import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../models/card_marketplace.dart';
import 'local_storage.dart';
import 'marketplace_service.dart';
import 'notification_services.dart';

class PriceAlertService {
  static const backgroundTaskName = 'price_alert_task';
  static const _backgroundTaskUniqueName = 'cardwatch_price_alerts';
  static const _notifiedKey = 'price_alerts_notified';
  static const _lastCheckKey = 'price_alerts_last_check';
  static const _autoCheckEnabledKey = 'price_alerts_auto_enabled';
  static const _autoCheckFrequencyKey = 'price_alerts_auto_frequency_minutes';
  static const int defaultFrequencyMinutes = 30;

  static Future<void> checkForLowerPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final notified = prefs.getStringList(_notifiedKey) ?? [];
    final notifiedSet = notified.toSet();

    for (final savedCard in LocalStorage().collection) {
      await _checkCollectionCard(savedCard, notifiedSet);
    }

    for (final savedCard in LocalStorage().watchlist) {
      await _checkWatchlistCard(savedCard, notifiedSet);
    }

    await prefs.setStringList(_notifiedKey, notifiedSet.toList());
    await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastCheckAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastCheckKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  static Future<bool> getAutoCheckEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoCheckEnabledKey) ?? true;
  }

  static Future<int> getAutoCheckFrequencyMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_autoCheckFrequencyKey) ?? defaultFrequencyMinutes;
  }

  static Future<void> saveAutoCheckSettings({
    required bool enabled,
    required int frequencyMinutes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoCheckEnabledKey, enabled);
    await prefs.setInt(_autoCheckFrequencyKey, frequencyMinutes);

    if (enabled) {
      await scheduleBackgroundChecks();
    } else {
      await cancelBackgroundChecks();
    }
  }

  static Future<void> scheduleBackgroundChecks() async {
    final enabled = await getAutoCheckEnabled();
    if (!enabled) {
      await cancelBackgroundChecks();
      return;
    }

    final frequencyMinutes = await getAutoCheckFrequencyMinutes();
    final safeFrequency = frequencyMinutes < 15 ? 15 : frequencyMinutes;
    await Workmanager().registerPeriodicTask(
      _backgroundTaskUniqueName,
      backgroundTaskName,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      frequency: Duration(minutes: safeFrequency),
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> cancelBackgroundChecks() {
    return Workmanager().cancelByUniqueName(_backgroundTaskUniqueName);
  }

  static Future<void> _checkCollectionCard(
    CardMarketplace savedCard,
    Set<String> notifiedSet,
  ) async {
    final offers = await _getOffers(savedCard);
    for (final offer in offers) {
      if (!_matchesSavedCard(savedCard, offer)) continue;

      final offerPrice = _parsePrice(offer.price.formatted);
      final savedPrice = _parsePrice(savedCard.price.formatted);
      if (offerPrice < savedPrice) {
        final uniqueKey = _alertKey(savedCard, offer, 'collection');
        if (!notifiedSet.contains(uniqueKey)) {
          await NotificationService.showCustom(
            title: 'Prezzo ribassato: ${_cardName(savedCard)}',
            body:
                'Ora disponibile a ${offer.price.formatted} da ${offer.user.username} (prima ${savedCard.price.formatted})',
          );
          notifiedSet.add(uniqueKey);
        }
      }
    }
  }

  static Future<void> _checkWatchlistCard(
    CardMarketplace savedCard,
    Set<String> notifiedSet,
  ) async {
    final threshold = _priceThresholdEur(savedCard);
    final targetPrice = threshold ?? _parsePrice(savedCard.price.formatted);
    final offers = await _getOffers(savedCard);

    for (final offer in offers) {
      if (!_matchesSavedCard(savedCard, offer)) continue;

      final offerPrice = _parsePrice(offer.price.formatted);
      if (offerPrice <= targetPrice) {
        final uniqueKey = _alertKey(savedCard, offer, 'watchlist_$targetPrice');
        if (!notifiedSet.contains(uniqueKey)) {
          await NotificationService.showCustom(
            title: 'Soglia raggiunta: ${_cardName(savedCard)}',
            body:
                '${offer.price.formatted} da ${offer.user.username} (soglia ${targetPrice.toStringAsFixed(2)} EUR)',
          );
          notifiedSet.add(uniqueKey);
        }
      }
    }
  }

  static Future<List<CardMarketplace>> _getOffers(
    CardMarketplace savedCard,
  ) async {
    final blueprintId = _blueprintId(savedCard);
    if (blueprintId > 0) {
      return MarketplaceService.getMarketCard(
        blueprintId,
        foil: savedCard.isFoil,
        language: savedCard.language == 'N/A' ? null : savedCard.language,
      );
    }

    final blueprints = await MarketplaceService.getBlueprintList(
      _cardName(savedCard),
    );
    if (blueprints.isEmpty) return [];

    return MarketplaceService.getMarketCard(
      blueprints.first.id,
      foil: savedCard.isFoil,
      language: savedCard.language == 'N/A' ? null : savedCard.language,
    );
  }

  static bool _matchesSavedCard(
    CardMarketplace savedCard,
    CardMarketplace offer,
  ) {
    if (offer.user.username == savedCard.user.username) return false;

    final sameCondition = offer.condition == savedCard.condition;
    final sameFoil = offer.isFoil == savedCard.isFoil;
    final sameSet = offer.expansion.nameEn == savedCard.expansion.nameEn;
    final sameLanguage =
        savedCard.language == 'N/A' || offer.language == savedCard.language;
    return sameCondition && sameFoil && sameSet && sameLanguage;
  }

  static String _alertKey(
    CardMarketplace saved,
    CardMarketplace offer,
    String scope,
  ) {
    return '${_blueprintId(saved)}_${saved.condition}_${saved.isFoil}_${saved.language}_${offer.user.username}_${offer.price.formatted}_$scope';
  }

  static int _blueprintId(CardMarketplace card) {
    final rawBlueprintId = card.propertiesHash['blueprintId'];
    if (rawBlueprintId is int) return rawBlueprintId;
    return int.tryParse(rawBlueprintId?.toString() ?? '') ?? 0;
  }

  static String _cardName(CardMarketplace card) {
    final storedName = card.propertiesHash['name']?.toString();
    if (storedName != null && storedName.trim().isNotEmpty) {
      return storedName;
    }
    return card.expansion.nameEn;
  }

  static double? _priceThresholdEur(CardMarketplace card) {
    final value = card.propertiesHash['priceThresholdEur'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static double _parsePrice(String formatted) {
    final cleaned = formatted
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    return double.tryParse(cleaned) ?? 99999.0;
  }
}
