import 'package:flutter/material.dart';

import '../l10n/l10n_helpers.dart';
import '../models/annotation.dart';

class NoteResult {
  final String note;
  final HighlightColor color;
  final bool delete;
  const NoteResult(this.note, this.color, {this.delete = false});
}

/// Edits a highlight's note and color. Returns null if cancelled.
Future<NoteResult?> showNoteDialog(
  BuildContext context, {
  required String quote,
  String note = '',
  required HighlightColor color,
  bool canDelete = false,
}) {
  final ctrl = TextEditingController(text: note);
  var selected = color;
  return showDialog<NoteResult>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(L10n.of(context).note),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: selected.swatch, width: 4),
                  ),
                ),
                child: Text(
                  quote,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: L10n.of(context).writeNote,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final c in HighlightColor.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: InkResponse(
                        onTap: () => setState(() => selected = c),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: c.swatch,
                          child: c == selected
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.black87,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (canDelete)
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, NoteResult('', selected, delete: true)),
              child: Text(L10n.of(context).removeHighlight),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(L10n.of(context).cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, NoteResult(ctrl.text.trim(), selected)),
            child: Text(L10n.of(context).save),
          ),
        ],
      ),
    ),
  );
}
