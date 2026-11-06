import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';

void main() {
  testWidgets('MovieLog 시작 화면의 필수 문구를 표시한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('FLUTTER 0주차'), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
