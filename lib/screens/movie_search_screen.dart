import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie/paged_movie_results.dart';

class MovieSearchScreen extends StatefulWidget {
  const MovieSearchScreen({super.key});
  @override
  State<MovieSearchScreen> createState() => _MovieSearchScreenState();
}

class _MovieSearchScreenState extends State<MovieSearchScreen> {
  final _text = TextEditingController();
  Timer? _debounce;
  bool _automatic = false;
  void _submit() {
    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    context.read<PagedMoviesViewModel>().loadInitial(searchQuery: _text.text);
  }

  void _changed(String value) {
    _debounce?.cancel();
    context.read<PagedMoviesViewModel>().invalidateQuery(value);
    if (!_automatic || value.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<PagedMoviesViewModel>().loadInitial(
          searchQuery: _text.text,
        );
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('영화 검색'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                key: const Key('movie-search-field'),
                controller: _text,
                textInputAction: TextInputAction.search,
                onChanged: _changed,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: '영화 제목',
                  hintText: '예: 배트맨',
                  suffixIcon: IconButton(
                    tooltip: '검색',
                    onPressed: _submit,
                    icon: const Icon(Icons.search),
                  ),
                ),
              ),
            ),
            SwitchListTile(
              key: const Key('debounce-toggle'),
              dense: true,
              title: const Text('입력 후 자동 검색'),
              subtitle: const Text('입력이 멈추고 0.5초 뒤 검색'),
              value: _automatic,
              onChanged: (value) {
                setState(() => _automatic = value);
                _changed(_text.text);
              },
            ),
            Expanded(child: PagedMovieResults(vm: vm)),
          ],
        ),
      ),
    );
  }
}
