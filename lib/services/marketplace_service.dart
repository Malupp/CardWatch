// lib/services/marketplace_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/card_blueprint.dart';
import '../models/card_marketplace.dart';
import '../models/enums/card_game_id.dart';

class MarketplaceService {
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Duration _marketplaceProductsInterval = Duration(
    milliseconds: 150,
  );
  static DateTime? _lastMarketplaceProductsRequest;

  static String get _baseUrl {
    final configured = dotenv.env['BASE_MARKETPLACE_API'] ?? '';
    return configured.replaceFirst(RegExp(r'/+$'), '');
  }

  static String get _token => dotenv.env['MARKETPLACE_TOKEN'] ?? '';
  static bool get _isConfigured => _baseUrl.isNotEmpty && _token.isNotEmpty;

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Uri _uri(String path, [Map<String, String>? queryParameters]) {
    final uri = Uri.parse('$_baseUrl$path');
    return queryParameters == null
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  static Future<void> _throttleMarketplaceProducts() async {
    final lastRequest = _lastMarketplaceProductsRequest;
    if (lastRequest != null) {
      final elapsed = DateTime.now().difference(lastRequest);
      final wait = _marketplaceProductsInterval - elapsed;
      if (!wait.isNegative) {
        await Future.delayed(wait);
      }
    }
    _lastMarketplaceProductsRequest = DateTime.now();
  }

  // Equivalente di getBlueprintList
  static Future<List<CardBlueprint>> getBlueprintList(String query) async {
    if (!_isConfigured) return [];

    try {
      final url = _uri('/blueprints', {
        'game_id': '${CardGameId.MAGIC.value}',
        'name': query,
      });
      final response = await http
          .get(url, headers: _headers)
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CardBlueprint.fromJson(json)).toList();
      } else {
        throw Exception(
          'Errore nel caricamento delle carte: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Errore di rete: $e');
    }
  }

  // Equivalente di getMarketCard
  static Future<List<CardMarketplace>> getMarketCard(
    int blueprintId, {
    bool? foil,
    String? language,
  }) async {
    if (!_isConfigured) return [];

    try {
      final query = {
        'blueprint_id': '$blueprintId',
        if (foil != null) 'foil': foil ? 'true' : 'false',
        if (language != null && language.trim().isNotEmpty)
          'language': language.trim(),
      };
      final url = _uri('/marketplace/products', query);
      late http.Response response;

      for (var attempt = 0; attempt < 2; attempt++) {
        await _throttleMarketplaceProducts();
        response = await http
            .get(url, headers: _headers)
            .timeout(_requestTimeout);
        if (response.statusCode != 429 || attempt == 1) break;
        await Future.delayed(const Duration(seconds: 1));
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Equivalente del pipe map di Angular
        final List<dynamic> cardList =
            jsonResponse[blueprintId.toString()] ?? [];
        return cardList.map((json) => CardMarketplace.fromJson(json)).toList();
      } else {
        throw Exception(
          'Errore nel caricamento del marketplace: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Errore di rete: $e');
    }
  }

  static Future<bool> checkToken() async {
    if (!_isConfigured) return false;

    try {
      final url = _uri('/blueprints', {
        'game_id': '${CardGameId.MAGIC.value}',
        'name': 'Black Lotus',
      });
      final response = await http
          .get(url, headers: _headers)
          .timeout(_requestTimeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
