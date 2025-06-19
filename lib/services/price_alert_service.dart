import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_storage.dart';
import 'marketplace_service.dart';
import 'notification_services.dart';
import '../models/card_marketplace.dart';

class PriceAlertService {
  static const _notifiedKey = 'price_alerts_notified';

  /// Controlla tutte le carte salvate e notifica se trova prezzi inferiori
  static Future<void> checkForLowerPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final notified = prefs.getStringList(_notifiedKey) ?? [];
    final notifiedSet = notified.toSet();

    final allCards = [...LocalStorage().collection, ...LocalStorage().watchlist];

    for (final savedCard in allCards) {
      // Ottieni tutte le offerte attuali per questa carta
      final offers = await MarketplaceService.getMarketCard(savedCard.expansion.id);
      for (final offer in offers) {
        // Salta se è lo stesso venditore
        if (offer.user.username == savedCard.user.username) continue;
        // Stessa condizione, foil, set
        final sameCondition = offer.condition == savedCard.condition;
        final sameFoil = offer.isFoil == savedCard.isFoil;
        final sameSet = offer.expansion.nameEn == savedCard.expansion.nameEn;
        if (!sameCondition || !sameFoil || !sameSet) continue;
        // Prezzo inferiore
        final offerPrice = _parsePrice(offer.price.formatted);
        final savedPrice = _parsePrice(savedCard.price.formatted);
        if (offerPrice < savedPrice) {
          final uniqueKey = _alertKey(savedCard, offer);
          if (!notifiedSet.contains(uniqueKey)) {
            // Notifica
            await NotificationService.showCustom(
              title: 'Prezzo ribassato: ${savedCard.expansion.nameEn}',
              body: 'Ora disponibile a ${offer.price.formatted} da ${offer.user.username} (prima ${savedCard.price.formatted})',
            );
            notifiedSet.add(uniqueKey);
          }
        }
      }
    }
    // Salva le notifiche inviate
    await prefs.setStringList(_notifiedKey, notifiedSet.toList());
  }

  static String _alertKey(CardMarketplace saved, CardMarketplace offer) {
    // Un identificatore unico per carta, condizione, foil, set, venditore e prezzo
    return '${saved.expansion.id}_${saved.condition}_${saved.isFoil}_${offer.user.username}_${offer.price.formatted}';
  }

  static double _parsePrice(String formatted) {
    // Estrae il numero dal formato tipo '1.00 €' o '1,00 €'
    final cleaned = formatted.replaceAll('€', '').replaceAll(',', '.').replaceAll(RegExp(r'[^0-9\.]'), '').trim();
    return double.tryParse(cleaned) ?? 99999.0;
  }
} 