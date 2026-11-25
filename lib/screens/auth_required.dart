import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_controller.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Pide login o registro. Devuelve true si el usuario quedó autenticado.
Future<bool> requireAccount(
  BuildContext context, {
  String message = 'Para continuar inicia sesión o crea una cuenta.',
}) async {
  final auth = context.read<AuthController>();
  if (auth.isAuthenticated) return true;

  final choice = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cuenta requerida',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(height: 1.4)),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext, 'login'),
                child: const Text('Iniciar sesión'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext, 'register'),
                child: const Text('Crear cuenta'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Seguir mirando'),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || choice == null) return false;

  if (choice == 'register') {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Inicia sesión.')),
      );
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen(asModal: true)),
      );
    }
  } else if (choice == 'login') {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen(asModal: true)),
    );
  }

  if (!context.mounted) return false;
  return context.read<AuthController>().isAuthenticated;
}
