//  OpenPlayer - Liberated Audio Experience
//  Copyright (C) 2024 [Tu Nombre o Alias]
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Affero General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Affero General Public License for more details.
//
//  Branding, logos and UI design are licensed under CC BY-NC-ND 4.0.
//  You should have received a copy of the GNU AGPL v3 along with this program.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/media_item.dart';

class AudiusService {
  static const String _appName = 'OPENPLAYER';

  // Lista de nodos de descubrimiento conocidos (actualizados)
  static const List<String> _fallbackNodes = [
    'https://discoveryprovider.audius.co',
    'https://discoveryprovider2.audius.co',
    'https://discoveryprovider3.audius.co',
  ];

  String? _activeNode;

  /// Obtiene un nodo de descubrimiento funcional
  Future<String> _getDiscoveryNode() async {
    if (_activeNode != null) return _activeNode!;

    // Intentar primero con la API oficial
    try {
      final response = await http.get(
        Uri.parse('https://api.audius.co'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nodes = data['data'] as List? ?? [];
        // Filtrar solo URLs que NO sean la propia api.audius.co
        final validNodes = nodes
            .map((n) => n.toString())
            .where((url) => url.contains('discoveryprovider'))
            .toList();

        if (validNodes.isNotEmpty) {
          _activeNode = validNodes.first;
          return _activeNode!;
        }
      }
    } catch (_) {
      // Fallará y usaremos la lista de respaldo
    }

    // Si la API oficial falla, probar los nodos de respaldo uno por uno
    for (final node in _fallbackNodes) {
      try {
        final testUri = Uri.parse('$node/v1/tracks/search')
            .replace(queryParameters: {'query': 'test', 'app_name': _appName});
        final testResponse =
            await http.get(testUri).timeout(const Duration(seconds: 5));
        if (testResponse.statusCode == 200) {
          _activeNode = node;
          return node;
        }
      } catch (_) {
        continue;
      }
    }

    // Si ningún nodo funciona, lanzar excepción
    throw Exception('No se pudo conectar con ningún nodo de Audius');
  }

  Future<List<MediaItem>> search(String query, {int limit = 10}) async {
    if (query.trim().length < 3) return [];

    try {
      final node = await _getDiscoveryNode();
      final uri = Uri.parse('$node/v1/tracks/search').replace(queryParameters: {
        'query': query,
        'app_name': _appName,
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Audius search HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final tracks = data['data'] as List? ?? [];

      final List<MediaItem> items = [];
      for (var t in tracks) {
        final trackId = t['id']?.toString();
        if (trackId == null || trackId.isEmpty) continue;

        final streamUrl = '$node/v1/tracks/$trackId/stream?app_name=$_appName';

        // Imagen
        String image = '';
        if (t['artwork'] != null && t['artwork']['_150x150'] != null) {
          image = t['artwork']['_150x150'];
        } else if (t['user'] != null && t['user']['profile_picture'] != null) {
          image = t['user']['profile_picture']['_150x150'] ?? '';
        }

        if (image.isNotEmpty && !image.startsWith('http')) {
          image = '$node/$image';
        }
        if (image.isEmpty) {
          image = 'https://via.placeholder.com/150?text=Audius';
        }

        items.add(MediaItem(
          id: 'aud-$trackId',
          title: t['title']?.toString() ?? 'Sin título',
          artist: t['user']?['name']?.toString() ?? 'Desconocido',
          url: streamUrl,
          imageUrl: image,
          source: MediaSource.audius, // ⬅️ Añadir
        ));

        if (items.length >= limit) break;
      }

      return items;
    } catch (e) {
      rethrow;
    }
  }
}
