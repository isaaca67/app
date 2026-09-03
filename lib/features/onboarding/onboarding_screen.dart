import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';
import 'package:stitch_cov_dark_mobile_login/screens/home_screen.dart';
import 'package:stitch_cov_dark_mobile_login/screens/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, this.onOnboardingComplete});

  final VoidCallback? onOnboardingComplete;

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> _onDone() async {
    final navigator = Navigator.of(navigatorKey.currentContext!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    onOnboardingComplete?.call();
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const HomeScreen();
    }

    return IntroductionScreen(
      globalBackgroundColor: AppTheme.darkBackground,
      pages: [
        PageViewModel(
          title: 'COV',
          body: 'Control de Operaciones y Ventas',
          image: const Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            bodyPadding: EdgeInsets.symmetric(horizontal: 24),
            pageColor: AppTheme.darkBackground,
          ),
        ),
        PageViewModel(
          title: 'Tu Catálogo',
          body: 'Gestiona tus productos, stock y precios desde un solo lugar.',
          image: const Center(
            child: Icon(
              Icons.inventory_2_outlined,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            bodyPadding: EdgeInsets.symmetric(horizontal: 24),
            pageColor: AppTheme.darkBackground,
          ),
        ),
        PageViewModel(
          title: 'Punto de Venta',
          body: 'Registra ventas rápidamente con escáner de código de barras.',
          image: const Center(
            child: Icon(
              Icons.point_of_sale_outlined,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            bodyPadding: EdgeInsets.symmetric(horizontal: 24),
            pageColor: AppTheme.darkBackground,
          ),
        ),
        PageViewModel(
          title: '¡Empieza!',
          body: 'Inicia sesión para continuar.',
          image: const Center(
            child: Icon(
              Icons.login_rounded,
              size: 100,
              color: AppTheme.primaryColor,
            ),
          ),
          decoration: const PageDecoration(
            titleTextStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyTextStyle: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            bodyPadding: EdgeInsets.symmetric(horizontal: 24),
            pageColor: AppTheme.darkBackground,
          ),
        ),
      ],
      onDone: () {
        _onDone();
      },
      onSkip: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      skip: const Text(
        'Omitir',
        style: TextStyle(color: Colors.white60),
      ),
      next: const Text(
        'Siguiente',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      done: const Text(
        'Empezar',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      dotsDecorator: DotsDecorator(
        size: const Size(10, 10),
        activeSize: const Size(22, 10),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        color: Colors.grey.shade800,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}