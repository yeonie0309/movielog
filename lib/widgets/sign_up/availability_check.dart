import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/services/member_api_service.dart';

class AvailabilityCheck extends StatefulWidget {
  const AvailabilityCheck({
    super.key,
    required this.controller,
    required this.isNickname,
  });

  final TextEditingController controller;
  final bool isNickname;

  @override
  State<AvailabilityCheck> createState() => _AvailabilityCheckState();
}

class _AvailabilityCheckState extends State<AvailabilityCheck> {
  bool _loading = false;
  String? _message;
  int _version = 0;
  late String _lastText;

  String get _kind => widget.isNickname ? 'nickname' : 'email';

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (_lastText == widget.controller.text) return;
    _lastText = widget.controller.text;
    _version++;
    setState(() {
      _message = null;
      _loading = false;
    });
  }

  Future<void> _check() async {
    final value = widget.controller.text.trim();
    final valid = widget.isNickname
        ? value.runes.length >= 2 && value.runes.length <= 12
        : RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
    if (!valid) {
      setState(
        () => _message = widget.isNickname
            ? '닉네임은 2~12자로 입력해 주세요.'
            : '올바른 이메일 형식을 입력해 주세요.',
      );
      return;
    }
    final version = ++_version;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final service = context.read<MemberApiService>();
      final available = widget.isNickname
          ? await service.checkNickname(value)
          : await service.checkEmail(value);
      if (!mounted || version != _version) return;
      setState(
        () => _message = available
            ? '사용 가능한 ${widget.isNickname ? '닉네임' : '이메일'}입니다.'
            : '이미 사용 중인 ${widget.isNickname ? '닉네임' : '이메일'}입니다.',
      );
    } catch (error) {
      if (!mounted || version != _version) return;
      setState(() => _message = memberApiErrorMessage(error));
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          key: Key('check-$_kind-button'),
          onPressed: _loading ? null : _check,
          child: Text(
            _loading ? '확인 중…' : '${widget.isNickname ? '닉네임' : '이메일'} 중복 확인',
          ),
        ),
      ),
      if (_message != null)
        Text(_message!, key: Key('$_kind-availability-message')),
    ],
  );
}
