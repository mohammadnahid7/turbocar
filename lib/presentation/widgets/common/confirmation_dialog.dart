/// Confirmation Dialog
/// Reusable confirmation dialog widget with async support
library;

import 'package:flutter/material.dart';
import '../../../core/constants/string_constants.dart';

class ConfirmationDialog extends StatefulWidget {
  final String title;
  final Widget content;
  final Future<void> Function() onConfirm;
  final VoidCallback? onCancel;
  final String confirmText;
  final String cancelText;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmText = StringConstants.confirm,
    this.cancelText = StringConstants.cancel,
  });

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Widget content,
    required Future<void> Function() onConfirm,
    VoidCallback? onCancel,
    String confirmText = StringConstants.confirm,
    String cancelText = StringConstants.cancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  bool _isLoading = false;

  Future<void> _handleConfirm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: widget.content,
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onCancel?.call();
                },
          child: Text(widget.cancelText),
        ),
        SizedBox(
          width: 100,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleConfirm,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.confirmText),
          ),
        ),
      ],
    );
  }
}
