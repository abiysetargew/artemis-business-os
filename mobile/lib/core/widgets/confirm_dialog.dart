import 'package:flutter/material.dart';

enum ConfirmDialogType { standard, destructive, highImpact }

class ConfirmResult {
  final bool confirmed;
  final String? typedValue;
  const ConfirmResult({required this.confirmed, this.typedValue});
}

class ConfirmDialog {
  /// Show a confirmation dialog. Returns true if user confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    ConfirmDialogType type = ConfirmDialogType.standard,
  }) async {
    final result = await showDialog<ConfirmResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmDialogContent(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
      ),
    );
    return result?.confirmed ?? false;
  }
}

class _ConfirmDialogContent extends StatefulWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final ConfirmDialogType type;

  const _ConfirmDialogContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.type,
  });

  @override
  State<_ConfirmDialogContent> createState() => _ConfirmDialogContentState();
}

class _ConfirmDialogContentState extends State<_ConfirmDialogContent> {
  final _typedController = TextEditingController();
  late Color _confirmColor;

  @override
  void initState() {
    super.initState();
    _confirmColor = widget.type == ConfirmDialogType.standard
        ? Theme.of(context).colorScheme.primary
        : Colors.red.shade700;
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHighImpact = widget.type == ConfirmDialogType.highImpact;
    final requiredText = widget.confirmLabel.toUpperCase();
    final canConfirm =
        !isHighImpact ||
        _typedController.text.trim().toUpperCase() == requiredText;

    return AlertDialog(
      icon: Icon(
        widget.type == ConfirmDialogType.standard
            ? Icons.help_outline
            : Icons.warning_amber_rounded,
        color: widget.type == ConfirmDialogType.standard
            ? Theme.of(context).colorScheme.primary
            : Colors.red.shade700,
        size: 32,
      ),
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          if (isHighImpact) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Type "$requiredText" to confirm:',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _typedController,
              autofocus: true,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const ConfirmResult(confirmed: false)),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(
                  ConfirmResult(
                    confirmed: true,
                    typedValue: _typedController.text,
                  ),
                )
              : null,
          style: FilledButton.styleFrom(backgroundColor: _confirmColor),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Show a snackbar with a colored background.
void showAppSnackBar(
  BuildContext context, {
  required String message,
  bool isError = false,
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  Color? bg;
  if (isError) {
    bg = Colors.red.shade700;
  } else if (isSuccess) {
    bg = Colors.green.shade700;
  }
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: bg,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
