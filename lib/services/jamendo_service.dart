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

class JamendoService {
  static const String _clientId = 'ac794c3c'; // Tu client_id real
  static const String _baseUrl = 'api.jamendo.com';

  Future<List<MediaItem>> search(String query, {int limit = 10}) async {
    if (query.trim().length < 3) return [];

    final uri = Uri.https(_baseUrl, '/v3.0/tracks', {
      'client_id': _clientId,
      'format': 'json',
      'search': query,
      'audioformat': 'mp32',
      'limit': limit.toString(),
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('Jamendo HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final results = data['results'] as List? ?? [];

    return results
        .map((t) {
          String audio = t['audio']?.toString() ?? '';
          if (audio.isEmpty) return null;

          String image = t['image']?.toString() ?? '';
          if (image.startsWith('//')) image = 'https:$image';
          if (image.isEmpty) {
            image = 'https://via.placeholder.com/300?text=Jamendo';
          }

          return MediaItem(
            id: 'jam-${t['id']}',
            title: t['name'] ?? 'Sin título',
            artist: t['artist_name'] ?? 'Desconocido',
            url: audio,
            imageUrl: image,
            source: MediaSource.jamendo, // ⬅️ Añadir
          );
        })
        .whereType<MediaItem>()
        .toList();
  }
}
