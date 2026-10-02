import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, String location) async {
    final router = AppRouter.create(
      initialLocation: location,
      genrePreference: _MemoryGenrePreference(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(routerConfig: router));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('시작 화면에서 회원가입 화면으로 이동한다', (tester) async {
    await pumpAt(tester, '/start');

    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byKey(const Key('nickname-field')), findsOneWidget);
  });

  testWidgets('NavigationBar로 홈, 영화, 마이페이지를 전환한다', (tester) async {
    await pumpAt(tester, '/home');

    expect(find.text('오늘의 추천'), findsOneWidget);
    await tester.tap(find.text('영화'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-grid')), findsOneWidget);

    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
  });

  testWidgets('영화 카드에서 Path ID 상세로 이동하고 뒤로 돌아온다', (tester) async {
    await pumpAt(tester, '/movies');

    await tester.tap(find.byKey(const Key('movie-card-1')));
    await tester.pumpAndSettle();

    expect(find.text('영화 상세'), findsOneWidget);
    expect(find.text('별빛 아래 우리'), findsOneWidget);
    expect(find.byKey(const Key('average-rating-label')), findsOneWidget);

    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-grid')), findsOneWidget);
  });

  testWidgets('BottomSheet 선택 결과를 Query 장르 필터로 적용한다', (tester) async {
    await pumpAt(tester, '/movies');

    await tester.tap(find.byKey(const Key('open-genre-filter-button')));
    await tester.pumpAndSettle();
    expect(find.text('장르 필터'), findsOneWidget);

    await tester.tap(find.byKey(const Key('genre-checkbox-드라마')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('apply-genre-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('드라마 · 1편'), findsOneWidget);
    expect(find.byKey(const Key('movie-card-1')), findsOneWidget);
    expect(find.byKey(const Key('movie-card-2')), findsNothing);
  });

  testWidgets('상세 화면에서 즐겨찾기 Snackbar를 사용한다', (tester) async {
    await pumpAt(tester, '/movies/1');

    await tester.tap(find.byKey(const Key('favorite-button')));
    await tester.pump();
    expect(find.text('즐겨찾기에 추가했어요.'), findsOneWidget);
  });

  testWidgets('상세 화면에서 평점 Dialog를 사용한다', (tester) async {
    await pumpAt(tester, '/movies/1');

    await tester.ensureVisible(
      find.byKey(const Key('open-rating-dialog-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-rating-dialog-button')));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);

    final dialogStars = find.descendant(
      of: find.byType(Dialog),
      matching: find.byIcon(Icons.star_rounded),
    );
    await tester.tap(dialogStars.at(3));
    await tester.pump();

    final confirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-rating-button')),
    );
    expect(confirmButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('reset-rating-button')));
    await tester.pump();
    expect(find.text('별을 눌러 평점을 선택해 주세요.'), findsOneWidget);
    final resetConfirmButton = tester.widget<FilledButton>(
      find.byKey(const Key('confirm-rating-button')),
    );
    expect(resetConfirmButton.onPressed, isNull);

    await tester.tap(dialogStars.at(3));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-rating-button')));
    await tester.pumpAndSettle();
    expect(find.text('4.0점으로 저장했어요.'), findsOneWidget);
  });
}

class _MemoryGenrePreference implements GenrePreferenceStore {
  Set<String> value = <String>{};

  @override
  Future<Set<String>> read() async => Set<String>.of(value);

  @override
  Future<void> save(Set<String> genres) async {
    value = Set<String>.of(genres);
  }
}
