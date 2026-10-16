import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member_rating.dart';
import '../data/services/member_api_service.dart';

class MemberRatingsScreen extends StatefulWidget {
  const MemberRatingsScreen({super.key});

  @override
  State<MemberRatingsScreen> createState() => _MemberRatingsScreenState();
}

class _MemberRatingsScreenState extends State<MemberRatingsScreen> {
  final _memberId = TextEditingController(text: '1');
  List<MemberRating>? _ratings;
  String? _error;
  bool _loading = false;
  int? _loadedMemberId;

  Future<void> _load() async {
    final id = int.tryParse(_memberId.text.trim());
    if (id == null || id <= 0) {
      setState(() {
        _ratings = null;
        _loadedMemberId = null;
        _error = '양의 정수 회원 ID를 입력해 주세요.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _ratings = null;
      _error = null;
      _loadedMemberId = null;
    });
    try {
      final ratings = await context.read<MemberApiService>().getRatings(id);
      if (!mounted) return;
      setState(() {
        _ratings = ratings;
        _loadedMemberId = id;
      });
    } catch (error) {
      if (mounted) setState(() => _error = memberApiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _memberId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('회원별 영화 평점')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('로그인 도입 전 실습용 조회입니다. 회원 ID를 직접 선택합니다.'),
          const SizedBox(height: 20),
          TextField(
            key: const Key('ratings-member-id-field'),
            controller: _memberId,
            enabled: !_loading,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '회원 ID'),
            onSubmitted: (_) {
              if (!_loading) _load();
            },
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('load-member-ratings-button'),
            onPressed: _loading
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    _load();
                  },
            child: const Text('평점 조회 / 다시 시도'),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(_error!, key: const Key('member-ratings-error')),
            ),
          if (_ratings != null) ...[
            const SizedBox(height: 20),
            Text(
              '회원 $_loadedMemberId · 평점 ${_ratings!.length}건 · 최신 등록순',
              key: const Key('member-ratings-count'),
            ),
            if (_ratings!.isEmpty)
              const Text('아직 남긴 평점이 없어요.', key: Key('member-ratings-empty')),
            for (final rating in _ratings!)
              Card(
                key: Key('member-rating-${rating.ratingId}'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TMDB 영화 #${rating.movieId} · ${rating.score}점'),
                      const SizedBox(height: 8),
                      Text(rating.comment ?? '코멘트 없음'),
                      Text('평점 ID ${rating.ratingId}'),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}
