import 'package:flutter/material.dart';

// ============================================================================
// 1. CAMBIA ESTA LÍNEA POR LA RUTA DE TU PANTALLA REAL:
// Si tu archivo está en lib/screens/login.dart, pon esa ruta aquí abajo.
// ============================================================================
import 'package:stitch_cov_dark_mobile_login/screens/login_screen.dart';

void main() {
  runApp(const COVApp());
}

class COVApp extends StatelessWidget {
  const COVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'COV Mobile',

      // Tema Oscuro Personalizado para tu aplicación
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF000000), // Fondo Negro Puro
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF7A8A), // Rosa/Salmón Acento
          surface: Color(0xFF121212),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF000000),
          elevation: 0,
        ),
      ),

      // ======================================================================
      // 2. CAMBIA 'LoginScreen()' POR EL NOMBRE DE TU WIDGET/PANTALLA:
      // (Es la clase que empieza por "class ..." dentro de tu archivo de pantalla)
      // ======================================================================
      home: const LoginScreen(),
    );
  }
}
