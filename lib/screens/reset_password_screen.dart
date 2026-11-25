import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../widgets/form_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialToken = '', this.fromDevelopment = false});

  final String initialToken;
  final bool fromDevelopment;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _token;
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _mode = AutovalidateMode.disabled;
  var _busy = false;
  var _serverFields = <String, String>{};
  String? _formError;

  @override
  void initState() {
    super.initState();
    _token = TextEditingController(text: widget.initialToken);
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _mode = AutovalidateMode.onUserInteraction;
      _serverFields = {};
      _formError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthController>().resetPassword(
            token: _token.text,
            password: _password.text,
            passwordConfirm: _confirm.text,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada. Inicia sesión.')),
      );
      navigator.popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _serverFields = error.fields;
        _formError = error.fields.isEmpty ? error.message : null;
      });
      _formKey.currentState?.validate();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NUEVA CLAVE')),
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
                      'Elige una contraseña',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mínimo 8 caracteres. El código viene en el correo o en el enlace de restablecimiento.',
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    if (widget.fromDevelopment) ...[
                      const FormBanner(
                        tone: FormBannerTone.success,
                        message:
                            'Modo desarrollo: no hay SMTP, así que abrimos esta pantalla con el código que habría llegado por correo.',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_formError != null) ...[
                      FormBanner(message: _formError!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _token,
                      decoration: const InputDecoration(labelText: 'Código del correo'),
                      validator: (value) {
                        if ((value ?? '').trim().length < 10) {
                          return 'Ingresa el código que llegó a tu correo';
                        }
                        return _serverFields['token'];
                      },
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _password,
                      label: 'Nueva contraseña',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        final text = value ?? '';
                        if (text.isEmpty) return 'La contraseña es obligatoria';
                        if (text.length < 8) return 'Mínimo 8 caracteres';
                        return _serverFields['password'];
                      },
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _confirm,
                      label: 'Verificar contraseña',
                      validator: (value) {
                        if ((value ?? '').isEmpty) return 'Verifica la contraseña';
                        if (value != _password.text) return 'Las contraseñas no coinciden';
                        return _serverFields['password_confirm'];
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(label: 'Guardar contraseña', busy: _busy, onPressed: _submit),
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
