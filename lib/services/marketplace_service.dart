
// lib/services/marketplace_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/card_blueprint.dart';
import '../models/card_marketplace.dart';
import '../models/enums/card_game_id.dart';

class MarketplaceService {
  static String get _baseUrl => dotenv.env['BASE_MARKETPLACE_API'] ?? '';
  static String get _token => dotenv.env['MARKETPLACE_TOKEN'] ?? '';

  static Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Content-Type': 'application/json',
  };

  // Equivalente di getBlueprintList
  static Future<List<CardBlueprint>> getBlueprintList(String query) async {
    try {
      
      final url = '$_baseUrl/blueprints?game_id=${CardGameId.MAGIC.value}&name=$query';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CardBlueprint.fromJson(json)).toList();
      } else {
        throw Exception('Errore nel caricamento delle carte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore di rete: $e');
    }
  }

  // Equivalente di getMarketCard
  static Future<List<CardMarketplace>> getMarketCard(int blueprintId) async {
    try {
      final url = '$_baseUrl/marketplace/products?blueprint_id=$blueprintId';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        // Equivalente del pipe map di Angular
        final List<dynamic> cardList = jsonResponse[blueprintId.toString()] ?? [];
        return cardList.map((json) => CardMarketplace.fromJson(json)).toList();
      } else {
        throw Exception('Errore nel caricamento del marketplace: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore di rete: $e');
    }
  }
}