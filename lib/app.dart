import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/theme.dart';
import 'screens/main_shell.dart';
import 'state/auth_controller.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';

class ImagoApp extends StatelessWidget {
  const ImagoApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiClient()),
        ChangeNotifierProvider(
          create: (context) => AuthController(prefs, context.read<ApiClient>())..bootstrap(),
        ),
        ChangeNotifierProvider(
          create: (context) => CatalogController(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(create: (_) => CartController(prefs)),
      ],
      child: MaterialApp(
        title: 'Imago',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.ready) return const _Splash();
    // Catálogo abierto para invitados; login solo al comprar o en cuenta.
    return const MainShell();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'IMAGO',
              style: TextStyle(
                fontSize: 28,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8),
            Text('Tienda de imágenes', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
