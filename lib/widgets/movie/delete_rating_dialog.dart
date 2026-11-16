import 'package:flutter/material.dart';

import '../movielog_button.dart';

/// Single deletion stays open until the request settles; failures are retryable.
class DeleteRatingDialog extends StatefulWidget {
  const DeleteRatingDialog({super.key, required this.onDelete});
  final Future<void> Function() onDelete;
  @override
  State<DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<DeleteRatingDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _delete() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (!mounted) return;
      setState(() => _busy = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is StateError
              ? error.message.toString()
              : '삭제에 실패했습니다. 다시 시도해 주세요.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('평점을 삭제할까요?'),
      content: Text(_error ?? '삭제한 평점은 복구할 수 없습니다.'),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        MovieLogButton(label: '삭제', isLoading: _busy, onPressed: _delete),
      ],
    ),
  );
}
