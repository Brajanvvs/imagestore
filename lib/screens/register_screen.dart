import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../widgets/form_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _mode = AutovalidateMode.disabled;
  var _busy = false;
  var _serverFields = <String, String>{};
  String? _formError;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _required(String? value, String label, String key) {
    if ((value ?? '').trim().isEmpty) return 'El campo $label es obligatorio';
    return _serverFields[key];
  }

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'El usuario es obligatorio';
    if (text.length < 3) return 'Mínimo 3 caracteres';
    return _serverFields['username'];
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'El correo es obligatorio';
    if (!emailPattern.hasMatch(text)) return 'El correo no tiene un formato válido';
    return _serverFields['email'];
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'La contraseña es obligatoria';
    if (text.length < 8) return 'Mínimo 8 caracteres';
    return _serverFields['password'];
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Verifica la contraseña';
    if (value != _password.text) return 'Las contraseñas no coinciden';
    return _serverFields['password_confirm'];
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
      await context.read<AuthController>().register(
            firstName: _firstName.text,
            lastName: _lastName.text,
            username: _username.text,
            email: _email.text,
            password: _password.text,
            passwordConfirm: _confirm.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
      appBar: AppBar(title: const Text('REGISTRO')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                      'Crear cuenta',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Regístrate para guardar imágenes y simular compras.',
                      style: TextStyle(color: AppColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    if (_formError != null) ...[
                      FormBanner(message: _formError!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _firstName,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (value) => _required(value, 'nombre', 'first_name'),
                      onChanged: (_) => _clear('first_name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _lastName,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                      validator: (value) => _required(value, 'apellidos', 'last_name'),
                      onChanged: (_) => _clear('last_name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: _validateUsername,
                      onChanged: (_) => _clear('username'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Correo electrónico'),
                      validator: _validateEmail,
                      onChanged: (_) => _clear('email'),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _password,
                      label: 'Contraseña',
                      textInputAction: TextInputAction.next,
                      validator: _validatePassword,
                      onChanged: (_) => _clear('password'),
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _confirm,
                      label: 'Verificar contraseña',
                      validator: _validateConfirm,
                      onChanged: (_) => _clear('password_confirm'),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(label: 'Registrarse', busy: _busy, onPressed: _submit),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : () => Navigator.of(context).pop(),
                        child: const Text('Ya tengo cuenta'),
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

  void _clear(String key) {
    if (!_serverFields.containsKey(key)) return;
    setState(() => _serverFields.remove(key));
  }
}
