import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../services/marketplace_service.dart';
import '../services/notification_services.dart';
import '../services/price_alert_service.dart';
import '../services/scryfall_api.dart';
import '../widgets/app_drawer.dart';
import 'package:provider/provider.dart';


class ProfilePage extends StatefulWidget {
  final Function(int) onNavigate;

  const ProfilePage({super.key, required this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _checkingPrices = false;
  bool _refreshingPrices = false;
  bool _checkingApiStatus = true;
  bool _savingAutoCheckSettings = false;
  bool? _cardTraderTokenValid;
  bool? _scryfallReachable;
  DateTime? _lastPriceCheckAt;
  bool _autoCheckEnabled = true;
  int _autoCheckFrequencyMinutes = PriceAlertService.defaultFrequencyMinutes;

  static const Map<int, String> _frequencyOptions = {
    15: 'Ogni 15 minuti',
    30: 'Ogni 30 minuti',
    60: 'Ogni ora',
    180: 'Ogni 3 ore',
    360: 'Ogni 6 ore',
    720: 'Ogni 12 ore',
    1440: 'Ogni giorno',
  };

  @override
  void initState() {
    super.initState();
    _loadApiStatus();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<LocalStorage>();

    final collection = storage.collection;
    final watchlist = storage.watchlist;
    final sellers = {
      ...collection
          .map((card) => card.user.username)
          .where((name) => name.isNotEmpty),
      ...watchlist
          .map((card) => card.user.username)
          .where((name) => name.isNotEmpty),
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
          _buildApiStatusSection(),
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
        _buildStatTile(
          Icons.collections_bookmark,
          'Collezione',
          '$collectionCount',
        ),
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
        Text('Notifiche', style: Theme.of(context).textTheme.titleMedium),
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
        _buildActionTile(
          Icons.update,
          _refreshingPrices ? 'Aggiornamento in corso...' : 'Aggiorna tutti i prezzi',
          'Aggiorna i prezzi senza mandare notifiche',
          _refreshingPrices ? null : _refreshAllPricesNow,
        ),
        _buildAutoCheckTile(),
      ],
    );
  }

  Widget _buildAutoCheckTile() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.autorenew),
              title: const Text('Controllo automatico prezzi'),
              subtitle: Text(
                _autoCheckEnabled
                    ? 'Attivo: ${_frequencyOptions[_autoCheckFrequencyMinutes] ?? 'ogni $_autoCheckFrequencyMinutes minuti'}'
                    : 'Disattivato',
              ),
              value: _autoCheckEnabled,
              onChanged: _savingAutoCheckSettings
                  ? null
                  : (value) => _saveAutoCheckSettings(enabled: value),
            ),
            DropdownButtonFormField<int>(
              value: _frequencyOptions.containsKey(_autoCheckFrequencyMinutes)
                  ? _autoCheckFrequencyMinutes
                  : PriceAlertService.defaultFrequencyMinutes,
              decoration: const InputDecoration(
                labelText: 'Frequenza controllo',
              ),
              items: _frequencyOptions.entries
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: !_autoCheckEnabled || _savingAutoCheckSettings
                  ? null
                  : (value) {
                      if (value == null) return;
                      _saveAutoCheckSettings(frequencyMinutes: value);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Stato API',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              icon: _checkingApiStatus
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _checkingApiStatus ? null : _loadApiStatus,
              tooltip: 'Aggiorna stato API',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatusTile(
          Icons.storefront,
          'CardTrader',
          _cardTraderTokenValid == true
              ? 'Token valido'
              : _cardTraderTokenValid == false
              ? 'Token non valido o API non raggiungibile'
              : 'Controllo in corso',
          _cardTraderTokenValid,
        ),
        _buildStatusTile(
          Icons.cloud,
          'Scryfall',
          _scryfallReachable == true
              ? 'API raggiungibile'
              : _scryfallReachable == false
              ? 'API non raggiungibile'
              : 'Controllo in corso',
          _scryfallReachable,
        ),
        _buildStatusTile(
          Icons.schedule,
          'Ultimo controllo prezzi',
          _lastPriceCheckAt == null
              ? 'Mai eseguito'
              : _formatDateTime(_lastPriceCheckAt!),
          _lastPriceCheckAt == null ? null : true,
        ),
      ],
    );
  }

  Widget _buildStatusTile(
    IconData icon,
    String title,
    String subtitle,
    bool? ok,
  ) {
    final color = ok == null
        ? Colors.grey
        : ok
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    final statusIcon = ok == null
        ? Icons.help_outline
        : ok
        ? Icons.check_circle
        : Icons.error_outline;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(statusIcon, color: color),
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scorciatoie', style: Theme.of(context).textTheme.titleMedium),
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

  Future<void> _refreshAllPricesNow() async {
    setState(() => _refreshingPrices = true);
    try {
      final updatedCount = await PriceAlertService.refreshAllPrices();
      _lastPriceCheckAt = await PriceAlertService.getLastCheckAt();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedCount > 0
                ? 'Prezzi aggiornati: $updatedCount carte'
                : 'Nessuna carta aggiornata',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aggiornamento prezzi non riuscito: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _refreshingPrices = false);
      }
    }
  }

  Future<void> _checkPricesNow() async {
    setState(() => _checkingPrices = true);
    try {
      await PriceAlertService.checkForLowerPrices();
      _lastPriceCheckAt = await PriceAlertService.getLastCheckAt();
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

  Future<void> _loadApiStatus() async {
    setState(() => _checkingApiStatus = true);
    final results = await Future.wait<Object?>([
      MarketplaceService.checkToken(),
      ScryfallApi.checkReachable(),
      PriceAlertService.getLastCheckAt(),
      PriceAlertService.getAutoCheckEnabled(),
      PriceAlertService.getAutoCheckFrequencyMinutes(),
    ]);

    if (!mounted) return;
    setState(() {
      _cardTraderTokenValid = results[0] as bool;
      _scryfallReachable = results[1] as bool;
      _lastPriceCheckAt = results[2] as DateTime?;
      _autoCheckEnabled = results[3] as bool;
      _autoCheckFrequencyMinutes = results[4] as int;
      _checkingApiStatus = false;
    });
  }

  Future<void> _saveAutoCheckSettings({
    bool? enabled,
    int? frequencyMinutes,
  }) async {
    final nextEnabled = enabled ?? _autoCheckEnabled;
    final nextFrequency = frequencyMinutes ?? _autoCheckFrequencyMinutes;

    setState(() => _savingAutoCheckSettings = true);
    try {
      await PriceAlertService.saveAutoCheckSettings(
        enabled: nextEnabled,
        frequencyMinutes: nextFrequency,
      );
      if (!mounted) return;
      setState(() {
        _autoCheckEnabled = nextEnabled;
        _autoCheckFrequencyMinutes = nextFrequency;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextEnabled
                ? 'Controllo automatico aggiornato'
                : 'Controllo automatico disattivato',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impostazione controllo automatico fallita: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAutoCheckSettings = false);
      }
    }
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  double _parsePrice(String formatted) {
    final cleaned = formatted
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 0;
  }
}
