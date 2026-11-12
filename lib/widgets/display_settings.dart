import 'package:flutter/material.dart';

import '../l10n/l10n_helpers.dart';
import '../services/settings_service.dart';

/// Display & accessibility settings, shared by the reader and the home
/// screen. [readingWpm], when given, is shown as an informational line.
void showDisplaySettings(
  BuildContext context,
  SettingsService settings, {
  double? readingWpm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => ListenableBuilder(
        listenable: settings,
        builder: (ctx, _) => _DisplaySettings(
          settings: settings,
          scroll: scroll,
          readingWpm: readingWpm,
        ),
      ),
    ),
  );
}

class _DisplaySettings extends StatelessWidget {
  final SettingsService settings;
  final ScrollController scroll;
  final double? readingWpm;
  const _DisplaySettings({
    required this.settings,
    required this.scroll,
    this.readingWpm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = settings;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    Widget slider({
      required String label,
      required String value,
      required double current,
      required double min,
      required double max,
      int? divisions,
      required ValueChanged<double> onChanged,
      IconData? lowIcon,
      IconData? highIcon,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Text(value, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
        Row(
          children: [
            if (lowIcon != null) Icon(lowIcon, size: 18),
            Expanded(
              child: Slider(
                value: current.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                label: value,
                onChanged: onChanged,
              ),
            ),
            if (highIcon != null) Icon(highIcon, size: 22),
          ],
        ),
      ],
    );

    final fonts = s.font.families;
    final l = L10n.of(context);
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text(l.displayAccessibility, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.language, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(l.appLanguage)),
            DropdownButton<String>(
              value: s.appLanguage,
              items: [
                DropdownMenuItem(value: '', child: Text(l.sameAsDevice)),
                for (final (code, name) in appLanguages)
                  DropdownMenuItem(value: code, child: Text(name)),
              ],
              onChanged: (v) => s.update((x) => x.appLanguage = v ?? ''),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Live preview of the reading text.
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: s.readerTheme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Text(
            l.previewText,
            textAlign: s.justify ? TextAlign.justify : TextAlign.start,
            style: TextStyle(
              color: s.readerTheme.foreground,
              fontSize: s.fontSize,
              height: s.lineHeight,
              fontFamily: fonts.first,
              fontFamilyFallback: fonts.skip(1).toList(),
              letterSpacing: s.fontSize * s.letterSpacing,
              wordSpacing: s.letterSpacing > 0
                  ? s.fontSize * s.letterSpacing * 1.5
                  : null,
            ),
          ),
        ),

        section(l.sectionText),
        SegmentedButton<ReaderTheme>(
          segments: [
            for (final t in ReaderTheme.values)
              ButtonSegment(value: t, label: Text(themeLabel(l, t))),
          ],
          selected: {s.readerTheme},
          onSelectionChanged: (v) => s.update((x) => x.readerTheme = v.first),
        ),
        const SizedBox(height: 12),
        SegmentedButton<ReaderFont>(
          segments: [
            for (final f in ReaderFont.values)
              ButtonSegment(
                value: f,
                // Each name in its own typeface, shrunk to fit if needed
                // (OpenDyslexic is very wide).
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    f.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(fontFamily: f.families.first, fontSize: 14),
                  ),
                ),
              ),
          ],
          selected: {s.font},
          onSelectionChanged: (v) => s.update((x) => x.font = v.first),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            fontDescription(l, s.font),
            style: theme.textTheme.bodySmall,
          ),
        ),
        slider(
          label: l.textSize,
          value: '${s.fontSize.round()}',
          current: s.fontSize,
          min: 14,
          max: 40,
          divisions: 26,
          lowIcon: Icons.text_decrease,
          highIcon: Icons.text_increase,
          onChanged: (v) => s.update((x) => x.fontSize = v),
        ),
        slider(
          label: l.lineSpacing,
          value: s.lineHeight.toStringAsFixed(1),
          current: s.lineHeight,
          min: 1.2,
          max: 2.6,
          divisions: 14,
          onChanged: (v) => s.update((x) => x.lineHeight = v),
        ),
        slider(
          label: l.letterSpacing,
          value: s.letterSpacing.abs() < 0.005
              ? l.normal
              : '${s.letterSpacing > 0 ? '+' : '−'}${(s.letterSpacing.abs() * 100).round()}%',
          current: s.letterSpacing,
          min: -0.08,
          max: 0.15,
          divisions: 23,
          onChanged: (v) => s.update((x) => x.letterSpacing = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.justifyText),
          subtitle: Text(l.justifySubtitle),
          value: s.justify,
          onChanged: (v) => s.update((x) => x.justify = v),
        ),

        section(l.sectionPage),
        slider(
          label: l.margins,
          value: '${s.margin.round()} px',
          current: s.margin,
          min: 8,
          max: 120,
          divisions: 28,
          onChanged: (v) => s.update((x) => x.margin = v),
        ),
        slider(
          label: l.lineWidth,
          value: '${s.lineWidth.round()} px',
          current: s.lineWidth,
          min: 360,
          max: 1200,
          divisions: 21,
          onChanged: (v) => s.update((x) => x.lineWidth = v),
        ),
        Text(l.lineWidthHint, style: theme.textTheme.bodySmall),

        section(l.sectionScreen),
        slider(
          label: l.brightness,
          value: '${(s.brightness * 100).round()}%',
          current: s.brightness,
          min: 0.3,
          max: 1,
          divisions: 14,
          lowIcon: Icons.brightness_low,
          highIcon: Icons.brightness_high,
          onChanged: (v) => s.update((x) => x.brightness = v),
        ),
        slider(
          label: l.warmth,
          value: s.warmth == 0 ? l.off : '${(s.warmth * 100).round()}%',
          current: s.warmth,
          min: 0,
          max: 1,
          divisions: 20,
          lowIcon: Icons.wb_sunny_outlined,
          highIcon: Icons.nightlight_outlined,
          onChanged: (v) => s.update((x) => x.warmth = v),
        ),
        Text(l.screenHint, style: theme.textTheme.bodySmall),

        if (readingWpm != null) ...[
          const SizedBox(height: 16),
          Text(
            l.readingSpeed(readingWpm!.round()),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: Text(l.resetDefaults),
            onPressed: s.resetDisplay,
          ),
        ),
      ],
    );
  }
}
