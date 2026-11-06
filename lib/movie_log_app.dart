import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key, this.routerConfig});

  final GoRouter? routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MovieLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: routerConfig ?? AppRouter.router,
    );
  }
}
