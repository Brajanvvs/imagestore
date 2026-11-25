import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../widgets/form_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.asModal = false, this.subtitle});

  /// Si es true, muestra botón de cierre y al entrar cierra la pantalla.
  final bool asModal;
  final String? subtitle;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  var _mode = AutovalidateMode.disabled;
  var _serverFields = <String, String>{};
  String? _formError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu usuario o correo';
    if (text.contains('@') && !emailPattern.hasMatch(text)) {
      return 'El correo no tiene un formato válido';
    }
    return _serverFields['identifier'];
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa tu contraseña';
    if (text.length < 6) return 'Mínimo 6 caracteres';
    return _serverFields['password'];
  }

  Future<void> _submit() async {
    setState(() {
      _mode = AutovalidateMode.onUserInteraction;
      _serverFields = {};
      _formError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await context.read<AuthController>().login(_identifier.text, _password.text);
      if (!mounted) return;
      if (widget.asModal || Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _serverFields = error.fields;
        _formError = error.fields.isEmpty ? error.message : null;
      });
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    final subtitle = widget.subtitle ??
        'Tu biblioteca de imágenes. La compra es una simulación.';
    return Scaffold(
      appBar: widget.asModal
          ? AppBar(
              title: const Text('ACCEDER'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                autovalidateMode: _mode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IMAGO',
                      style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Inicia sesión',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, height: 1.05),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    if (_formError != null) ...[
                      FormBanner(message: _formError!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _identifier,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Usuario o correo'),
                      validator: _validateIdentifier,
                      onChanged: (_) => _clearServer('identifier'),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _password,
                      label: 'Contraseña',
                      textInputAction: TextInputAction.done,
                      validator: _validatePassword,
                      onChanged: (_) => _clearServer('password'),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Iniciar sesión',
                      busy: busy,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta?', style: TextStyle(color: AppColors.muted)),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final created = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                  if (created == true && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cuenta creada. Inicia sesión.')),
                                    );
                                  }
                                },
                          child: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Text(
                        'Cuenta demo: usuario demo · contraseña demo1234',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearServer(String key) {
    if (!_serverFields.containsKey(key)) return;
    setState(() => _serverFields.remove(key));
  }
}
