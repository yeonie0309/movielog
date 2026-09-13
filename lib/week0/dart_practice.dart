class Movie {
  const Movie({required this.id, required this.title});

  final int id;
  final String title;
}

void main() {
  const movies = <Movie>[
    Movie(id: 1, title: '인사이드 아웃'),
    Movie(id: 2, title: '인터스텔라'),
    Movie(id: 3, title: '라라랜드'),
  ];

  for (final movie in movies) {
    print(movie.title);
  }

  String? nickname;
  final safeNickname = nickname ?? '무비러버';
  print('닉네임: $safeNickname');
}
