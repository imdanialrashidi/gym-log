import 'package:lift_core/lift_core.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/digit_style_scope.dart';
import '../l10n/l10n.dart';

/// Edits a plain-text note. Returns `null` when cancelled and `''` when the
/// user cleared it, so callers can distinguish cancel from clear.
Future<String?> showNoteDialog(
  BuildContext context, {
  required String title,
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        _NoteDialog(title: title, initialValue: initialValue),
  );
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.title, this.initialValue});

  final String title;
  final String? initialValue;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final AppLocalizations l10n = context.l10n;
    // The model limit is measured in UTF-16 code units. The field's own
    // maxLength counts grapheme clusters, so check the model unit explicitly.
    if (_controller.text.trim().length > maximumNoteLength) {
      setState(() => _error = l10n.noteTooLong);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('note-field'),
        controller: _controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        maxLength: maximumNoteLength,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: context.digits(l10n.noteHint(maximumNoteLength)),
          errorText: _error,
          alignLabelWithHint: true,
        ),
        buildCounter:
            (
              BuildContext context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              final int count = _controller.text.trim().length;
              return Text(context.digits('$count/$maximumNoteLength'));
            },
        onChanged: (_) {
          if (_error != null) {
            setState(() => _error = null);
          } else {
            setState(() {});
          }
        },
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('note-save'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
