import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/tmdb_config.dart';
import 'core/network/tmdb_client.dart';
import 'core/network/movielog_client.dart';
import 'core/network/workbook_client.dart';
import 'data/services/member_check_service.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/member_api_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({
    super.key,
    this.routerConfig,
    this.catalogService,
    this.memberApiService,
    this.memberCheckService,
    this.ratingApiService,
    this.movieDetailService,
  });

  final GoRouter? routerConfig;
  final MovieCatalogService? catalogService;
  final MemberApiService? memberApiService;
  final MemberCheckService? memberCheckService;
  final RatingApiService? ratingApiService;
  final MovieDetailService? movieDetailService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MemberApiService>(
          create: (_) =>
              memberApiService ?? HttpMemberApiService(createMovieLogClient()),
        ),
        Provider(
          create: (_) => createWorkbookClient(),
          dispose: (_, dio) => dio.close(),
        ),
        Provider<MemberCheckService>(
          create: (context) =>
              memberCheckService ?? MemberCheckService(context.read()),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              ratingApiService ?? RatingApiService(context.read()),
        ),
        Provider<MovieCatalogService>(
          create: (context) {
            if (catalogService != null) return catalogService!;
            final token = TmdbConfig.accessToken;
            return token.isEmpty
                ? const MissingTokenMovieService()
                : TmdbMovieService(createTmdbClient(token));
          },
        ),
        Provider<MovieDetailService>(
          create: (context) {
            if (movieDetailService != null) return movieDetailService!;
            final catalog = context.read<MovieCatalogService>();
            return catalog is MovieDetailService
                ? catalog as MovieDetailService
                : const MissingTokenMovieService();
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'MovieLog',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: routerConfig ?? AppRouter.router,
      ),
    );
  }
}
