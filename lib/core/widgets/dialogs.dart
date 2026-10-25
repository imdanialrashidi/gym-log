import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// Prompts for a required name and returns the trimmed value, or `null` when
/// cancelled.
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String label,
  String initialValue = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        _NameDialog(title: title, label: label, initialValue: initialValue),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.label,
    required this.initialValue,
  });

  final String title;
  final String label;
  final String initialValue;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('name-dialog-field'),
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: widget.label),
          validator: (String? value) => value == null || value.trim().isEmpty
              ? l10n.errorNameRequired
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('name-dialog-save'),
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Confirms a destructive action. Returns false when dismissed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final AppLocalizations l10n = context.l10n;
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
            foregroundColor: Theme.of(dialogContext).colorScheme.onError,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
