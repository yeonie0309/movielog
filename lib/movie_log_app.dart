import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/tmdb_config.dart';
import 'core/network/tmdb_client.dart';
import 'core/network/movielog_client.dart';
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
  });

  final GoRouter? routerConfig;
  final MovieCatalogService? catalogService;
  final MemberApiService? memberApiService;

  @override
  Widget build(BuildContext context) {
    return Provider<MemberApiService>(
      create: (_) =>
          memberApiService ?? HttpMemberApiService(createMovieLogClient()),
      child: Provider<MovieCatalogService>(
        create: (context) {
          if (catalogService != null) return catalogService!;
          final token = TmdbConfig.accessToken;
          return token.isEmpty
              ? const MissingTokenMovieService()
              : TmdbMovieService(createTmdbClient(token));
        },
        child: MaterialApp.router(
          title: 'MovieLog',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: routerConfig ?? AppRouter.router,
        ),
      ),
    );
  }
}
