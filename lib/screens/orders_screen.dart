import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/store_order.dart';
import '../state/auth_controller.dart';
import '../widgets/app_image.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<StoreOrder> _orders = [];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = context.read<ApiClient>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await api.orders();
      if (!mounted) return;
      setState(() {
        _orders = data.map((item) => StoreOrder.fromJson(item as Map<String, dynamic>)).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().user?.firstName ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('MIS PEDIDOS')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.ink))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          name.isEmpty
                              ? 'Todavía no tienes pedidos.'
                              : '$name, todavía no tienes pedidos.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.ink,
                      onRefresh: _load,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _OrderCard(order: _orders[index]),
                      ),
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final StoreOrder order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Pedido #${order.id}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(money(order.total), style: const TextStyle(color: AppColors.copper, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatDate(order.createdAt), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 2),
            Text(order.statusLabel, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(width: 42, height: 42, child: AppImage(url: item.imageUrl)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.quantity} × ${item.title}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
