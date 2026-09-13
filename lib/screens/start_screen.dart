import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  static const _backgroundColor = Color(0xFFFAF9F5);
  static const _primaryColor = Color(0xFF563894);
  static const _titleColor = Color(0xFF1D1B20);
  static const _bodyColor = Color(0xFF514D5B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 52, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeContent(),
              const Spacer(),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'FLUTTER 0주차',
          style: TextStyle(
            color: StartScreen._bodyColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 64),
        Icon(
          Icons.movie_outlined,
          color: StartScreen._primaryColor,
          size: 72,
          semanticLabel: 'MovieLog 영화 아이콘',
        ),
        SizedBox(height: 72),
        Text(
          '영화의 순간을\n기록하세요',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: StartScreen._titleColor,
            fontSize: 38,
            fontWeight: FontWeight.w400,
            height: 1.25,
            letterSpacing: -1.2,
          ),
        ),
        SizedBox(height: 20),
        Text(
          '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: StartScreen._bodyColor,
            fontSize: 17,
            fontWeight: FontWeight.w400,
            height: 1.55,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
