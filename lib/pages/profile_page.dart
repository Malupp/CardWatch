import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../services/notification_services.dart';
import '../services/price_alert_service.dart';
import '../widgets/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  final Function(int) onNavigate;

  const ProfilePage({
    super.key,
    required this.onNavigate,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _checkingPrices = false;

  @override
  Widget build(BuildContext context) {
    final collection = LocalStorage().collection;
    final watchlist = LocalStorage().watchlist;
    final sellers = {
      ...collection.map((card) => card.user.username).where((name) => name.isNotEmpty),
      ...watchlist.map((card) => card.user.username).where((name) => name.isNotEmpty),
    };
    final trackedValue = collection.fold<double>(
      0,
      (sum, card) => sum + _parsePrice(card.price.formatted),
    );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 64,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 32),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Profilo'),
      ),
      drawer: AppDrawer(currentIndex: 4, onSelect: widget.onNavigate),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _buildHeader(collection.length, watchlist.length),
          const SizedBox(height: 16),
          _buildStatsSection(
            collectionCount: collection.length,
            watchlistCount: watchlist.length,
            sellersCount: sellers.length,
            trackedValue: trackedValue,
          ),
          const SizedBox(height: 16),
          _buildNotificationSection(),
          const SizedBox(height: 16),
          _buildNavigationSection(),
        ],
      ),
    );
  }

  Widget _buildHeader(int collectionCount, int watchlistCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.person, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CardWatch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  '$collectionCount carte salvate, $watchlistCount sotto osservazione',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection({
    required int collectionCount,
    required int watchlistCount,
    required int sellersCount,
    required double trackedValue,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildStatTile(Icons.collections_bookmark, 'Collezione', '$collectionCount'),
        _buildStatTile(Icons.favorite, 'Watchlist', '$watchlistCount'),
        _buildStatTile(Icons.storefront, 'Venditori', '$sellersCount'),
        _buildStatTile(
          Icons.payments,
          'Valore salvato',
          trackedValue > 0 ? trackedValue.toStringAsFixed(2) : '0.00',
        ),
      ],
    );
  }

  Widget _buildStatTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(label, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notifiche',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          Icons.notifications_active,
          'Invia notifica di prova',
          'Verifica subito permessi e canale Android',
          () async {
            await NotificationService.showNow(
              title: 'CardWatch',
              body: 'Le notifiche sono attive.',
            );
          },
        ),
        _buildActionTile(
          Icons.price_check,
          _checkingPrices ? 'Controllo in corso...' : 'Controlla prezzi ora',
          'Cerca offerte piu basse per collection e watchlist',
          _checkingPrices ? null : _checkPricesNow,
        ),
      ],
    );
  }

  Widget _buildNavigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scorciatoie',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildActionTile(
          Icons.collections,
          'Apri collezione',
          'Carte che hai salvato',
          () => widget.onNavigate(1),
        ),
        _buildActionTile(
          Icons.favorite,
          'Apri watchlist',
          'Carte monitorate per prezzo',
          () => widget.onNavigate(2),
        ),
        _buildActionTile(
          Icons.shuffle,
          'Modalita Draft',
          'Sfoglia carte per espansione',
          () => widget.onNavigate(3),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        enabled: onTap != null,
        onTap: onTap,
      ),
    );
  }

  Future<void> _checkPricesNow() async {
    setState(() => _checkingPrices = true);
    try {
      await PriceAlertService.checkForLowerPrices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Controllo prezzi completato')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Controllo prezzi non riuscito: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingPrices = false);
      }
    }
  }

  double _parsePrice(String formatted) {
    final cleaned = formatted
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }
}
