import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../widgets/form_banner.dart';
import '../widgets/primary_button.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _mode = AutovalidateMode.disabled;
  var _busy = false;
  String? _message;
  var _messageIsError = true;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _mode = AutovalidateMode.onUserInteraction;
      _message = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final token = await context.read<AuthController>().requestReset(_email.text);
      if (!mounted) return;
      if (token != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ResetPasswordScreen(initialToken: token, fromDevelopment: true),
          ),
        );
        return;
      }
      setState(() {
        _messageIsError = false;
        _message = 'Si el correo está registrado, enviamos un enlace para restablecer la contraseña.';
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messageIsError = true;
        _message = error.fields['email'] ?? error.message;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RECUPERAR')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                autovalidateMode: _mode,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.05),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Escribe el correo de tu cuenta. El backend envía un enlace de restablecimiento y, si no hay correo configurado, la app abre la pantalla para elegir una nueva contraseña.',
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    if (_message != null) ...[
                      FormBanner(
                        message: _message!,
                        tone: _messageIsError ? FormBannerTone.error : FormBannerTone.success,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'El correo es obligatorio';
                        if (!emailPattern.hasMatch(text)) return 'El correo no tiene un formato válido';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(label: 'Enviar enlace', busy: _busy, onPressed: _submit),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
                          );
                        },
                        child: const Text('Ya tengo un código'),
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
}
