import 'package:flutter/material.dart';

import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ProfileScreen(),
    );
  }
}
