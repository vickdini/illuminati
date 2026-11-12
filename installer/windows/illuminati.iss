; Windows installer for Illuminati (Inno Setup 6).
;
; Build the app first, then compile from the repository root:
;   flutter build windows --release
;   iscc /DAppVersion=1.2.3 installer\windows\illuminati.iss
; The installer is written to build\installer\Illuminati-windows-setup.exe.
;
; It installs for the current user only (no admin rights) into
; %LOCALAPPDATA%\Programs\Illuminati, a folder the app can write to, so it
; can update itself. Uninstalling keeps the user's library and settings.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif

[Setup]
; Never change AppId: Windows uses it to recognise later versions.
AppId={{4112AA00-1A10-4B26-B7DF-301973D8479A}
AppName=Illuminati
AppVersion={#AppVersion}
AppVerName=Illuminati {#AppVersion}
AppPublisher=Illuminati
AppPublisherURL=https://github.com/vickdini/illuminati
AppSupportURL=https://github.com/vickdini/illuminati/issues
AppUpdatesURL=https://github.com/vickdini/illuminati/releases
AppCopyright=Free software; the books are in the public domain
VersionInfoVersion={#AppVersion}
VersionInfoProductName=Illuminati
VersionInfoDescription=Illuminati setup
PrivilegesRequired=lowest
DefaultDirName={autopf}\Illuminati
DisableProgramGroupPage=yes
DisableDirPage=auto
DisableReadyPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Close Illuminati if it's running, and don't restart Windows.
CloseApplications=yes
RestartApplications=no
OutputDir=..\..\build\installer
OutputBaseFilename=Illuminati-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\illuminati.exe
UninstallDisplayName=Illuminati
WizardStyle=modern
WizardImageFile=wizard-large-100.bmp,wizard-large-200.bmp
WizardSmallImageFile=wizard-small-100.bmp,wizard-small-200.bmp
Compression=lzma2/max
SolidCompression=yes
; Use the Windows display language when it's one of these, without asking.
ShowLanguageDialog=auto
LanguageDetectionMethod=uilanguage

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Illuminati"; Filename: "{app}\illuminati.exe"
Name: "{autodesktop}\Illuminati"; Filename: "{app}\illuminati.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\illuminati.exe"; Description: "{cm:LaunchProgram,Illuminati}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; Files added by later updates, which the uninstaller doesn't know about.
; The library and settings (in %APPDATA%\Illuminati) are kept.
Type: filesandordirs; Name: "{app}"
