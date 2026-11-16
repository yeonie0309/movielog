import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'data/token_storage.dart';
import 'data/services/auth_api_service.dart';
import 'view_models/auth_view_model.dart';
import 'core/network/auth_interceptor.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/config/tmdb_config.dart';
import 'core/network/tmdb_client.dart';
import 'core/network/movielog_client.dart';
import 'core/network/workbook_client.dart';
import 'data/services/member_check_service.dart';
import 'data/services/sign_up_service.dart';
import 'view_models/learning_member_session.dart';
import 'data/services/rating_api_service.dart';
import 'data/services/member_api_service.dart';
import 'data/services/tmdb_movie_service.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatefulWidget {
  const MovieLogApp({
    super.key,
    this.routerConfig,
    this.catalogService,
    this.memberApiService,
    this.memberCheckService,
    this.ratingApiService,
    this.movieDetailService,
    this.learningSession,
    this.authViewModel,
    this.tokenStorage,
    this.authenticatedRatingApiService,
  });

  final AuthViewModel? authViewModel;
  final TokenStorage? tokenStorage;
  final AuthenticatedRatingApiService? authenticatedRatingApiService;
  final GoRouter? routerConfig;
  final MovieCatalogService? catalogService;
  final MemberApiService? memberApiService;
  final MemberCheckService? memberCheckService;
  final RatingApiService? ratingApiService;
  final MovieDetailService? movieDetailService;
  final LearningMemberSession? learningSession;

  @override
  State<MovieLogApp> createState() => _MovieLogAppState();
}

class _MovieLogAppState extends State<MovieLogApp> {
  late final Dio _publicClient;
  late final Dio _authClient;
  late final Dio _memberClient;
  late final AuthViewModel? _auth;
  late final GoRouter _router;
  late final AuthenticatedRatingApiService _tokenRatings;
  @override
  void initState() {
    super.initState();
    _publicClient = createWorkbookClient();
    _authClient = createWorkbookClient();
    final enabled = widget.routerConfig == null || widget.authViewModel != null;
    _auth = enabled
        ? widget.authViewModel ??
              AuthViewModel(
                AuthApiService(_publicClient, _authClient),
                widget.tokenStorage ?? SecureTokenStorage(),
              )
        : null;
    if (_auth != null) {
      _authClient.interceptors.add(
        AuthInterceptor(
          _auth.storage,
          sessionVersion: () => _auth.sessionVersion,
          onExpired: _auth.expireSession,
        ),
      );
    }
    _memberClient = _auth == null
        ? createMovieLogClient()
        : (createWorkbookClient()..options.baseUrl += '/v7');
    _tokenRatings =
        widget.authenticatedRatingApiService ??
        AuthenticatedRatingApiService(_publicClient, _authClient);
    _router =
        widget.routerConfig ?? AppRouter.create(useTmdb: true, auth: _auth);
    _auth?.restoreSession();
  }

  @override
  void dispose() {
    if (widget.routerConfig == null) _router.dispose();
    if (widget.authViewModel == null) _auth?.dispose();
    _publicClient.close();
    _authClient.close();
    _memberClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => widget.learningSession ?? LearningMemberSession(),
        ),
        if (_auth != null)
          ChangeNotifierProvider<AuthViewModel>.value(value: _auth),
        Provider<AuthenticatedRatingApiService>.value(value: _tokenRatings),
        Provider<MemberApiService>(
          create: (_) =>
              widget.memberApiService ?? HttpMemberApiService(_memberClient),
        ),
        Provider(create: (_) => _publicClient),
        Provider<MemberCheckService>(
          create: (context) =>
              widget.memberCheckService ??
              SignUpService(
                context.read(),
                version: _auth == null ? 'v6' : 'v7',
              ),
        ),
        Provider<RatingApiService>(
          create: (context) =>
              widget.ratingApiService ?? RatingApiService(context.read()),
        ),
        Provider<MovieCatalogService>(
          create: (context) {
            if (widget.catalogService != null) return widget.catalogService!;
            final token = TmdbConfig.accessToken;
            return token.isEmpty
                ? const MissingTokenMovieService()
                : TmdbMovieService(createTmdbClient(token));
          },
        ),
        Provider<MovieDetailService>(
          create: (context) {
            if (widget.movieDetailService != null) {
              return widget.movieDetailService!;
            }
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
        routerConfig: _router,
      ),
    );
  }
}
