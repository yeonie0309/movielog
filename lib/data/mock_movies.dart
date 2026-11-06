import '../models/movie.dart';

const mockMovies = <Movie>[
  Movie(
    id: 1,
    title: '별빛 아래 우리',
    genre: '드라마',
    year: 2024,
    posterAsset: 'assets/images/posters/hero_under_the_starlight.jpg',
    overview: '서로 다른 시간을 살아온 두 사람이 오래된 극장에서 만나 각자의 꿈을 다시 발견하는 이야기입니다.',
    runtimeMinutes: 118,
    averageRating: 4.5,
  ),
  Movie(
    id: 2,
    title: '심연을 걷는 자',
    genre: '스릴러',
    year: 2025,
    posterAsset: 'assets/images/posters/poster_abyss_walker.jpg',
    overview: '한 번도 공개되지 않았던 해저 도시를 조사하던 탐사대가 마주한 비밀을 따라갑니다.',
    runtimeMinutes: 126,
    averageRating: 4.1,
  ),
  Movie(
    id: 3,
    title: '공허의 메아리',
    genre: 'SF',
    year: 2025,
    posterAsset: 'assets/images/posters/poster_echoes_of_the_void.jpg',
    overview: '우주 끝에서 수신된 정체불명의 신호가 인류의 기억과 연결되며 벌어지는 SF 미스터리입니다.',
    runtimeMinutes: 132,
    averageRating: 4.3,
  ),
  Movie(
    id: 4,
    title: '네 번째 오후',
    genre: '로맨스',
    year: 2023,
    posterAsset: 'assets/images/posters/poster_fourth_afternoon.jpg',
    overview: '매주 같은 카페에서 마주치던 두 사람이 네 번째 오후에 처음으로 대화를 시작합니다.',
    runtimeMinutes: 104,
    averageRating: 3.9,
  ),
  Movie(
    id: 5,
    title: '밤의 그림자',
    genre: '스릴러',
    year: 2024,
    posterAsset: 'assets/images/posters/poster_night_shadows.jpg',
    overview: '잠들지 않는 도시에서 사라진 친구의 흔적을 좇는 하룻밤의 추적극입니다.',
    runtimeMinutes: 112,
    averageRating: 4.0,
  ),
  Movie(
    id: 6,
    title: '속삭이는 숲',
    genre: '판타지',
    year: 2025,
    posterAsset: 'assets/images/posters/poster_whispering_woods.jpg',
    overview: '마음속 소원을 들려주는 숲에 들어간 소녀가 마을의 오래된 약속을 발견합니다.',
    runtimeMinutes: 109,
    averageRating: 4.4,
  ),
];

List<String> get movieGenres {
  final genres = mockMovies.map((movie) => movie.genre).toSet().toList();
  genres.sort();
  return genres;
}

Movie? findMovieById(int? id) {
  for (final movie in mockMovies) {
    if (movie.id == id) return movie;
  }
  return null;
}
