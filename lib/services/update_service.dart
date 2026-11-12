import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'catalog_service.dart';

/// This build's version, set by the GitHub workflow with
/// `--dart-define=APP_VERSION=1.2.3`. Local builds leave it empty, which turns
/// updates off so a development build never replaces itself.
const appVersion = String.fromEnvironment('APP_VERSION');

/// Where releases are published. Overridable for testing.
const _releaseFeed = String.fromEnvironment(
  'UPDATE_FEED',
  defaultValue:
      'https://api.github.com/repos/vickdini/illuminati/releases/latest',
);

enum UpdateState {
  /// Nothing to do (up to date, offline, or updates off).
  idle,

  /// Downloading the new version in the background.
  downloading,

  /// Windows/Linux: downloaded and unpacked; installs when the app closes, or
  /// now with [UpdateService.restartNow].
  ready,

  /// A newer version exists but can't be installed from here (macOS, or an
  /// install folder the app can't write to); [UpdateService.openDownloadPage].
  available,

  /// Android: the system installer was opened.
  installing,
}

/// Checks GitHub for a newer release when the app starts and installs it:
///
/// - Windows and Linux: downloads and unpacks it in the background, then a
///   small script copies it over this installation after the app exits (when
///   the user closes it, or right away with [restartNow]).
/// - Android: downloads the APK and opens the system installer, which always
///   asks the user to confirm.
/// - macOS: the sandbox doesn't allow an app to replace itself, so the user
///   is pointed to the download page.
class UpdateService extends ChangeNotifier {
  static const _channel = MethodChannel('illuminati/update');

  UpdateState state = UpdateState.idle;

  /// The newer version, e.g. "1.2.0", once one is found.
  String? latestVersion;

  /// Download progress (0..1) while [state] is [UpdateState.downloading].
  double? progress;

  String? _releasePage;
  String? _staged; // unpacked new version, or Windows setup program
  Directory? _updateDir; // illuminati-update/<version>
  File? _logFile;
  bool _installStarted = false;

  static bool get enabled =>
      appVersion.isNotEmpty &&
      (Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS ||
          Platform.isAndroid);

  static const _windowsSetup = 'Illuminati-windows-setup.exe';
  static const _linuxAppImage = 'Illuminati-linux-x86_64.AppImage';

  /// The AppImage file this copy runs from, if it's an AppImage. The app's
  /// own folder is then a read-only image, so the update replaces this file.
  static String? get _appImage =>
      Platform.isLinux ? Platform.environment['APPIMAGE'] : null;

  /// What the update replaces: the AppImage file, or the app's folder.
  static String get _installTarget => _appImage ?? _installDir.path;

  /// Whether this copy was installed with the Windows setup program. It's then
  /// updated by running the new setup program silently, which also updates
  /// the version shown in Windows' list of installed apps.
  static bool get _installedWithSetup =>
      Platform.isWindows &&
      File(p.join(_installDir.path, 'unins000.exe')).existsSync();

  /// The release files for this platform (as named by the GitHub workflow),
  /// best first.
  static List<String> get _assetNames {
    if (Platform.isAndroid) return ['Illuminati-android.apk'];
    if (Platform.isWindows) {
      return [
        if (_installedWithSetup) _windowsSetup,
        'Illuminati-windows-x64.zip',
      ];
    }
    if (Platform.isLinux) {
      return [
        _appImage == null ? 'Illuminati-linux-x64.tar.gz' : _linuxAppImage,
      ];
    }
    if (Platform.isMacOS) return ['Illuminati-macos.zip'];
    return [];
  }

  /// Checks for a newer release and gets it ready. Never throws: an update
  /// that fails is simply tried again the next time the app starts.
  Future<void> run() async {
    if (!enabled) return;
    try {
      await _run();
    } catch (e) {
      _log('failed: $e');
      if (state == UpdateState.downloading) _set(UpdateState.idle);
    }
  }

  /// Appends to illuminati-update/update.log in the temp folder, to help
  /// diagnose updates that don't install.
  void _log(String message) {
    debugPrint('Update: $message');
    try {
      _logFile?.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  Future<void> _run() async {
    final root = Directory(
      p.join((await getTemporaryDirectory()).path, 'illuminati-update'),
    );
    await root.create(recursive: true);
    _logFile = File(p.join(root.path, 'update.log'));
    _log('this is $appVersion; checking $_releaseFeed');
    final res = await http
        .get(
          Uri.parse(_releaseFeed),
          headers: {
            'User-Agent': CatalogService.userAgent,
            'Accept': 'application/vnd.github+json',
          },
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      _log('release feed returned ${res.statusCode}');
      return;
    }
    final release = jsonDecode(res.body) as Map<String, dynamic>;
    final tag = (release['tag_name'] as String? ?? '').replaceFirst('v', '');
    if (!isNewer(tag, appVersion)) {
      _log('latest is $tag; up to date');
      return;
    }
    latestVersion = tag;
    _releasePage = release['html_url'] as String?;

    final assets = (release['assets'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final asset = _assetNames
        .map((n) => assets.where((a) => a['name'] == n).firstOrNull)
        .nonNulls
        .firstOrNull;
    if (asset == null || Platform.isMacOS || !await _canInstallHere()) {
      _log("$tag is available but can't be installed here");
      _set(UpdateState.available);
      return;
    }

    final dir = Directory(p.join(root.path, tag));
    _updateDir = dir;
    await _removeOtherVersions(root, keep: dir);
    final file = File(p.join(dir.path, asset['name'] as String));
    final unpacked = Directory(p.join(dir.path, 'unpacked'));
    final setup = asset['name'] == _windowsSetup;

    // Already downloaded on an earlier start (e.g. the app was killed before
    // it could install).
    final done = File(p.join(dir.path, 'complete'));
    if (!await done.exists()) {
      await dir.create(recursive: true);
      await _download(asset, file);
      if (!Platform.isAndroid && !setup && asset['name'] != _linuxAppImage) {
        if (await unpacked.exists()) await unpacked.delete(recursive: true);
        final from = file.path, to = unpacked.path;
        await Isolate.run(() => extractFileToDisk(from, to));
      }
      await done.writeAsString(tag);
      _log('downloaded $tag');
    }

    if (Platform.isAndroid) {
      _set(UpdateState.installing);
      await _channel.invokeMethod('install', {'path': file.path});
      return;
    }
    _staged = setup || asset['name'] == _linuxAppImage
        ? file.path
        : _findAppFolder(unpacked)?.path;
    if (_staged == null) throw StateError('The update has no app in it');
    _log('$tag is ready to install from $_staged');
    _set(UpdateState.ready);
  }

  /// Whether version [a] (e.g. "1.10.0") is newer than [b] ("1.9.2").
  static bool isNewer(String a, String b) {
    List<int> parts(String v) =>
        v.split('+').first.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final x = parts(a), y = parts(b);
    for (var i = 0; i < 3; i++) {
      final xi = i < x.length ? x[i] : 0, yi = i < y.length ? y[i] : 0;
      if (xi != yi) return xi > yi;
    }
    return false;
  }

  Future<void> _download(Map<String, dynamic> asset, File file) async {
    _set(UpdateState.downloading);
    final part = File('${file.path}.part');
    final client = http.Client();
    try {
      final req = http.Request(
        'GET',
        Uri.parse(asset['browser_download_url'] as String),
      )..headers['User-Agent'] = CatalogService.userAgent;
      final res = await client.send(req).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        throw HttpException('Update download failed (${res.statusCode})');
      }
      final total = asset['size'] as int? ?? res.contentLength ?? 0;
      var received = 0;
      final sink = part.openWrite();
      try {
        await for (final chunk in res.stream.timeout(
          const Duration(seconds: 60),
        )) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            progress = received / total;
            notifyListeners();
          }
        }
      } finally {
        await sink.close();
      }
      if (total > 0 && received != total) {
        throw const HttpException('Update download was incomplete');
      }
      // GitHub publishes each file's SHA-256; check it when present.
      final digest = asset['digest'] as String?;
      if (digest != null && digest.startsWith('sha256:')) {
        final actual = await sha256.bind(part.openRead()).first;
        if ('sha256:$actual' != digest) {
          throw const HttpException('Update download is corrupt');
        }
      }
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
    } finally {
      client.close();
    }
  }

  /// The folder in the unpacked archive that holds the app's executable.
  static Directory? _findAppFolder(Directory unpacked) {
    final exe = Platform.isWindows ? 'illuminati.exe' : 'illuminati';
    if (File(p.join(unpacked.path, exe)).existsSync()) return unpacked;
    for (final d in unpacked.listSync().whereType<Directory>()) {
      if (File(p.join(d.path, exe)).existsSync()) return d;
    }
    return null;
  }

  static Directory get _installDir => File(Platform.resolvedExecutable).parent;

  /// Whether this installation's folder can be written to (it can't under
  /// e.g. C:\Program Files without admin rights).
  static Future<bool> _canInstallHere() async {
    if (Platform.isAndroid) return true;
    try {
      final probe = File(
        p.join(
          p.dirname(_appImage ?? p.join(_installDir.path, 'x')),
          '.update-check',
        ),
      );
      await probe.writeAsString('');
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _removeOtherVersions(
    Directory root, {
    required Directory keep,
  }) async {
    if (!await root.exists()) return;
    await for (final e in root.list()) {
      if (p.equals(e.path, keep.path) || p.basename(e.path) == 'update.log') {
        continue;
      }
      try {
        await e.delete(recursive: true);
      } catch (_) {}
    }
  }

  void _set(UpdateState s) {
    state = s;
    notifyListeners();
  }

  /// Installs the update and starts the new version.
  Future<void> restartNow() async {
    if (await _startInstaller(relaunch: true)) exit(0);
  }

  /// Called when the app is about to close: installs the update after it
  /// exits, without starting it again.
  Future<void> installOnExit() => _startInstaller(relaunch: false);

  /// Starts the script that waits for this process to end, copies the new
  /// version over this installation and optionally starts it.
  Future<bool> _startInstaller({required bool relaunch}) async {
    final staged = _staged, dir = _updateDir;
    _log('installing (relaunch: $relaunch, state: ${state.name})');
    if (state != UpdateState.ready ||
        staged == null ||
        dir == null ||
        _installStarted) {
      return false;
    }
    _installStarted = true;
    try {
      if (Platform.isWindows) {
        final script = File(p.join(dir.path, 'install.ps1'));
        await script.writeAsString(_windowsScript);
        await Process.start('powershell.exe', [
          '-NoProfile',
          '-ExecutionPolicy',
          'Bypass',
          '-WindowStyle',
          'Hidden',
          '-File',
          script.path,
          '-AppPid',
          '$pid',
          '-Source',
          staged,
          '-Target',
          _installDir.path,
          '-Mode',
          staged.endsWith('.exe') ? 'setup' : 'copy',
          '-Relaunch',
          relaunch ? '1' : '0',
          // Not "detached": Windows PowerShell started without a console
          // exits at once. A normal child process outlives the app anyway.
        ]);
      } else {
        final script = File(p.join(dir.path, 'install.sh'));
        await script.writeAsString(_linuxScript);
        await Process.start('/bin/sh', [
          script.path,
          '$pid',
          staged,
          _installTarget,
          relaunch ? '1' : '0',
        ], mode: ProcessStartMode.detached);
      }
      _log('installer started');
      return true;
    } catch (e) {
      _log('could not start the installer: $e');
      _installStarted = false;
      return false;
    }
  }

  Future<void> openDownloadPage() async {
    final url = _releasePage;
    if (url != null) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

// Waits for the app to exit, then either runs the new setup program silently
// (Mode "setup", for copies installed with it) or copies the new files over
// the old ones (robocopy retries while files are still locked), and
// optionally starts the app again. Progress goes to the app's update.log.
const _windowsScript = r'''
param([int]$AppPid, [string]$Source, [string]$Target, [string]$Mode, [string]$Relaunch)
$log = Join-Path (Split-Path $PSScriptRoot) 'update.log'
function Log($m) { Add-Content $log "$(Get-Date -Format o) installer: $m" }
Log "waiting for process $AppPid to exit"
try { Wait-Process -Id $AppPid -Timeout 120 -ErrorAction Stop } catch {}
Start-Sleep -Milliseconds 500
if ($Mode -eq 'setup') {
  $p = Start-Process $Source -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/SP-' -Wait -PassThru
  Log "ran $Source (exit code $($p.ExitCode); 0 is success)"
} else {
  robocopy $Source $Target /E /R:10 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
  Log "copied to $Target (robocopy exit code $LASTEXITCODE; below 8 is success)"
}
if ($Relaunch -eq '1') { Start-Process (Join-Path $Target 'illuminati.exe'); Log 'restarted' }
''';

const _linuxScript = r'''
APP_PID="$1"; SOURCE="$2"; TARGET="$3"; RELAUNCH="$4"
LOG="$(dirname "$0")/../update.log"
log() { echo "$(date -Iseconds) installer: $1" >> "$LOG"; }
log "waiting for process $APP_PID to exit"
while kill -0 "$APP_PID" 2>/dev/null; do sleep 0.3; done
if [ -f "$SOURCE" ]; then
  # AppImage: replace the file in one step.
  APP="$TARGET"
  if cp -f "$SOURCE" "$TARGET.new" && chmod +x "$TARGET.new" && mv -f "$TARGET.new" "$TARGET"; then
    log "replaced $TARGET"
  else
    log "replacing $TARGET failed"
  fi
else
  APP="$TARGET/illuminati"
  if cp -rf "$SOURCE"/. "$TARGET"/ && chmod +x "$APP"; then
    log "copied to $TARGET"
  else
    log "copy to $TARGET failed"
  fi
fi
if [ "$RELAUNCH" = "1" ]; then
  nohup "$APP" >/dev/null 2>&1 &
  log "restarted"
fi
''';
