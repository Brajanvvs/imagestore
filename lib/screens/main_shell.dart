import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_controller.dart';
import '../state/cart_controller.dart';
import '../state/catalog_controller.dart';
import '../widgets/user_avatar.dart';
import 'auth_required.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'register_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;
  int? _boundUserId;
  var _catalogLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCatalog());
  }

  Future<void> _loadCatalog() async {
    if (_catalogLoaded || !mounted) return;
    _catalogLoaded = true;
    await context.read<CatalogController>().load();
  }

  void _syncCartUser(int? userId) {
    if (_boundUserId == userId) return;
    _boundUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartController>().bindUser(userId);
    });
  }

  Future<void> _select(int index) async {
    final auth = context.read<AuthController>();
    if (!auth.isAuthenticated && index != 0) {
      final reason = index == 1
          ? 'Para ver el carrito e iniciar una compra necesitas una cuenta.'
          : 'Para ver y editar tu perfil necesitas iniciar sesión.';
      final ok = await requireAccount(context, message: reason);
      if (!ok || !mounted) return;
    }
    setState(() => _index = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  Future<void> _openLogin() async {
    _scaffoldKey.currentState?.closeDrawer();
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const LoginScreen(asModal: true)),
    );
  }

  Future<void> _openRegister() async {
    _scaffoldKey.currentState?.closeDrawer();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Inicia sesión.')),
      );
      await _openLogin();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text(
          'Se eliminará el token de esta sesión. Podrás seguir mirando el catálogo como invitado.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Salir')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    await cart.bindUser(null);
    await auth.logout();
    if (!mounted) return;
    setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final cartCount = context.watch<CartController>().count;
    final user = auth.user;
    final loggedIn = auth.isAuthenticated;
    _syncCartUser(user?.id);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  children: [
                    if (loggedIn)
                      UserAvatar(user: user!, radius: 28)
                    else
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFE7E1D8),
                        child: Icon(Icons.person_outline, color: AppColors.muted),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loggedIn ? user!.fullName : 'Invitado',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            loggedIn ? '@${user!.username}' : 'Mira el catálogo sin cuenta',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Inicio'),
                onTap: () => _select(0),
              ),
              if (loggedIn) ...[
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Mis pedidos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const OrdersScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Perfil'),
                  onTap: () => _select(2),
                ),
                const Spacer(),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Cerrar sesión'),
                  onTap: _logout,
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Iniciar sesión'),
                  onTap: _openLogin,
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('Crear cuenta'),
                  onTap: _openRegister,
                ),
                const Spacer(),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onMenu: _openDrawer, onOpenCart: () => _select(1)),
          CartScreen(onMenu: _openDrawer, onGoHome: () => _select(0)),
          if (loggedIn)
            ProfileScreen(onMenu: _openDrawer, key: ValueKey('profile-${user!.id}'))
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _select,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _CartIcon(active: false, count: loggedIn ? cartCount : 0),
            activeIcon: _CartIcon(active: true, count: loggedIn ? cartCount : 0),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.active, required this.count});

  final bool active;
  final int count;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(active ? Icons.shopping_bag : Icons.shopping_bag_outlined);
    if (count <= 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
