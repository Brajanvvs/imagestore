import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../widgets/form_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _username;
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  var _profileMode = AutovalidateMode.disabled;
  var _passwordMode = AutovalidateMode.disabled;
  var _savingProfile = false;
  var _savingPassword = false;
  var _profileFields = <String, String>{};
  var _passwordFields = <String, String>{};
  String? _profileError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user!;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
    _username = TextEditingController(text: user.username);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _username.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _profileMode = AutovalidateMode.onUserInteraction;
      _profileFields = {};
      _profileError = null;
    });
    if (!(_profileKey.currentState?.validate() ?? false)) return;
    setState(() => _savingProfile = true);
    try {
      await context.read<AuthController>().updateProfile(
            firstName: _firstName.text,
            lastName: _lastName.text,
            username: _username.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _profileFields = error.fields;
        _profileError = error.fields.isEmpty ? error.message : null;
      });
      _profileKey.currentState?.validate();
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _passwordMode = AutovalidateMode.onUserInteraction;
      _passwordFields = {};
      _passwordError = null;
    });
    if (!(_passwordKey.currentState?.validate() ?? false)) return;
    setState(() => _savingPassword = true);
    try {
      await context.read<AuthController>().changePassword(
            currentPassword: _currentPassword.text,
            newPassword: _newPassword.text,
            newPasswordConfirm: _confirmPassword.text,
          );
      if (!mounted) return;
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _passwordFields = error.fields;
        _passwordError = error.fields.isEmpty ? error.message : null;
      });
      _passwordKey.currentState?.validate();
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onMenu,
          icon: const Icon(Icons.menu),
          tooltip: 'Menú',
        ),
        title: const Text('PERFIL'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: Column(
              children: [
                UserAvatar(user: user, radius: 42),
                const SizedBox(height: 12),
                Text(user.fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('@${user.username}', style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(user.email, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Datos de la cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Form(
            key: _profileKey,
            autovalidateMode: _profileMode,
            child: Column(
              children: [
                if (_profileError != null) ...[
                  FormBanner(message: _profileError!),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'El nombre es obligatorio';
                    return _profileFields['first_name'];
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) return 'Los apellidos son obligatorios';
                    return _profileFields['last_name'];
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'El usuario es obligatorio';
                    if (text.length < 3) return 'Mínimo 3 caracteres';
                    return _profileFields['username'];
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Guardar cambios',
                  busy: _savingProfile,
                  onPressed: _saveProfile,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text('Cambiar contraseña', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Form(
            key: _passwordKey,
            autovalidateMode: _passwordMode,
            child: Column(
              children: [
                if (_passwordError != null) ...[
                  FormBanner(message: _passwordError!),
                  const SizedBox(height: 12),
                ],
                PasswordField(
                  controller: _currentPassword,
                  label: 'Contraseña actual',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Ingresa tu contraseña actual';
                    return _passwordFields['current_password'];
                  },
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: _newPassword,
                  label: 'Nueva contraseña',
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final text = value ?? '';
                    if (text.isEmpty) return 'La contraseña es obligatoria';
                    if (text.length < 8) return 'Mínimo 8 caracteres';
                    return _passwordFields['new_password'];
                  },
                ),
                const SizedBox(height: 12),
                PasswordField(
                  controller: _confirmPassword,
                  label: 'Verificar contraseña',
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Verifica la contraseña';
                    if (value != _newPassword.text) return 'Las contraseñas no coinciden';
                    return _passwordFields['new_password_confirm'];
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Actualizar contraseña',
                  busy: _savingPassword,
                  onPressed: _savePassword,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
