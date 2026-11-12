import 'package:flutter/material.dart';

import '../services/settings_service.dart';

/// Display & accessibility settings, shared by the reader and the home
/// screen. [readingWpm], when given, is shown as an informational line.
void showDisplaySettings(BuildContext context, SettingsService settings, {double? readingWpm}) {
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
  const _DisplaySettings({required this.settings, required this.scroll, this.readingWpm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = settings;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 4),
          child: Text(title,
              style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
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
    }) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(children: [
              Expanded(child: Text(label)),
              Text(value, style: theme.textTheme.labelMedium),
            ]),
          ),
          Row(children: [
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
          ]),
        ]);

    final fonts = s.font.families;
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        Text('Display & accessibility', style: theme.textTheme.titleLarge),
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
            'It was the best of times, it was the worst of times; it was the age '
            'of wisdom, it was the age of foolishness.',
            textAlign: s.justify ? TextAlign.justify : TextAlign.start,
            style: TextStyle(
              color: s.readerTheme.foreground,
              fontSize: s.fontSize,
              height: s.lineHeight,
              fontFamily: fonts.first,
              fontFamilyFallback: fonts.skip(1).toList(),
              letterSpacing: s.fontSize * s.letterSpacing,
              wordSpacing: s.letterSpacing > 0 ? s.fontSize * s.letterSpacing * 1.5 : null,
            ),
          ),
        ),

        section('Text'),
        SegmentedButton<ReaderTheme>(
          segments: [
            for (final t in ReaderTheme.values) ButtonSegment(value: t, label: Text(t.label)),
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
                // Each name in its own typeface.
                label: Text(f.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                        fontFamily: f.families.first,
                        fontSize: f == ReaderFont.dyslexic ? 12 : 14)),
              ),
          ],
          selected: {s.font},
          onSelectionChanged: (v) => s.update((x) => x.font = v.first),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(s.font.description, style: theme.textTheme.bodySmall),
        ),
        slider(
          label: 'Text size',
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
          label: 'Line spacing',
          value: s.lineHeight.toStringAsFixed(1),
          current: s.lineHeight,
          min: 1.2,
          max: 2.6,
          divisions: 14,
          onChanged: (v) => s.update((x) => x.lineHeight = v),
        ),
        slider(
          label: 'Letter spacing',
          value: s.letterSpacing.abs() < 0.005
              ? 'Normal'
              : '${s.letterSpacing > 0 ? '+' : '−'}${(s.letterSpacing.abs() * 100).round()}%',
          current: s.letterSpacing,
          min: -0.08,
          max: 0.15,
          divisions: 23,
          onChanged: (v) => s.update((x) => x.letterSpacing = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Justify text'),
          subtitle: const Text('Even right edge. Turn off for even spacing between words.'),
          value: s.justify,
          onChanged: (v) => s.update((x) => x.justify = v),
        ),

        section('Page'),
        slider(
          label: 'Margins',
          value: '${s.margin.round()} px',
          current: s.margin,
          min: 8,
          max: 120,
          divisions: 28,
          onChanged: (v) => s.update((x) => x.margin = v),
        ),
        slider(
          label: 'Line width',
          value: '${s.lineWidth.round()} px',
          current: s.lineWidth,
          min: 360,
          max: 1200,
          divisions: 21,
          onChanged: (v) => s.update((x) => x.lineWidth = v),
        ),
        Text('Shorter lines are easier to follow; the text column is never '
            'wider than the screen minus the margins.',
            style: theme.textTheme.bodySmall),

        section('Screen'),
        slider(
          label: 'Brightness',
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
          label: 'Warmth',
          value: s.warmth == 0 ? 'Off' : '${(s.warmth * 100).round()}%',
          current: s.warmth,
          min: 0,
          max: 1,
          divisions: 20,
          lowIcon: Icons.wb_sunny_outlined,
          highIcon: Icons.nightlight_outlined,
          onChanged: (v) => s.update((x) => x.warmth = v),
        ),
        Text('Brightness and warmth apply to the whole app, on top of your '
            'device’s own settings. Warmth reduces blue light, like a night light.',
            style: theme.textTheme.bodySmall),

        if (readingWpm != null) ...[
          const SizedBox(height: 16),
          Text('Reading speed: about ${readingWpm!.round()} words per minute '
              '(learned as you read).',
              style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset to defaults'),
            onPressed: s.resetDisplay,
          ),
        ),
      ],
    );
  }
}
