import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({
    super.key,
    required this.genres,
    required this.initialSelection,
  });

  final List<String> genres;
  final Set<String> initialSelection;

  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> _draftSelection;

  @override
  void initState() {
    super.initState();
    _draftSelection = {...widget.initialSelection};
  }

  void _toggleGenre(String genre, bool selected) {
    setState(() {
      if (selected) {
        _draftSelection.add(genre);
      } else {
        _draftSelection.remove(genre);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Material(
          color: AppColors.warmWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '장르 필터',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(_draftSelection.clear),
                      child: const Text('전체 해제'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('genre-filter-list'),
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.genres.length,
                  itemBuilder: (context, index) {
                    final genre = widget.genres[index];
                    return CheckboxListTile(
                      key: Key('genre-checkbox-$genre'),
                      value: _draftSelection.contains(genre),
                      onChanged: (value) => _toggleGenre(genre, value ?? false),
                      title: Text(genre),
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      key: const Key('apply-genre-filter-button'),
                      onPressed: () => Navigator.pop(context, _draftSelection),
                      child: Text(
                        _draftSelection.isEmpty
                            ? '전체 영화 보기'
                            : '${_draftSelection.length}개 장르 적용',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
