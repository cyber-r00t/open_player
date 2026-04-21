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
import '../models/radio_station.dart';

class RadioService {
  static const String _baseUrl = 'all.api.radio-browser.info';
  static const Map<String, String> _headers = {
    'User-Agent': 'OpenPlayer/1.0',
    'Accept': 'application/json',
  };

  /// Obtiene emisoras populares priorizando España y Latinoamérica
  Future<List<RadioStation>> getTopStations({int limit = 30}) async {
    // Estrategia: primero buscamos por tags geográficos populares
    final tags = [
      'españa',
      'spain',
      'latino',
      'mexico',
      'argentina',
      'colombia',
      'chile',
      'peru',
      'rock',
      'pop',
      'top40'
    ];
    List<RadioStation> allStations = [];

    // Intentar con cada tag hasta tener suficientes resultados
    for (final tag in tags) {
      if (allStations.length >= limit) break;
      final stations =
          await _fetchStationsByTag(tag, limit: limit - allStations.length);
      // Evitar duplicados por ID
      for (final s in stations) {
        if (!allStations.any((element) => element.id == s.id)) {
          allStations.add(s);
        }
      }
    }

    // Si aún no tenemos suficientes, completar con las más escuchadas globalmente
    if (allStations.length < limit) {
      final global = await _fetchStations(limit: limit - allStations.length);
      for (final s in global) {
        if (!allStations.any((element) => element.id == s.id)) {
          allStations.add(s);
        }
      }
    }

    return allStations.take(limit).toList();
  }

  /// Busca emisoras por texto (nombre o tags)
  Future<List<RadioStation>> searchStations(String query) async {
    if (query.trim().isEmpty) return getTopStations();

    // Primero búsqueda por nombre
    List<RadioStation> results = await _fetchStations(
      filter: query,
      limit: 30,
    );

    // Si no hay resultados, buscar por tags (quitando tildes para mejorar coincidencias)
    if (results.isEmpty) {
      final simpleQuery = _removeAccents(query.toLowerCase());
      final tags = simpleQuery.split(' ').where((w) => w.length > 2).toList();
      for (final tag in tags) {
        final tagResults = await _fetchStationsByTag(tag, limit: 10);
        for (final s in tagResults) {
          if (!results.any((element) => element.id == s.id)) {
            results.add(s);
          }
        }
      }
    }

    return results;
  }

  Future<List<RadioStation>> _fetchStations({
    List<String>? countryCodes,
    int limit = 50,
    String? filter,
  }) async {
    final queryParams = <String, String>{
      'order': 'clickcount',
      'reverse': 'true',
      'limit': limit.toString(),
      'hidebroken': 'true',
    };

    if (countryCodes != null && countryCodes.isNotEmpty) {
      queryParams['countrycode'] = countryCodes.join(',');
    }
    if (filter != null && filter.isNotEmpty) {
      queryParams['name'] = filter;
    }

    final uri = Uri.https(_baseUrl, '/json/stations/search', queryParams);

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RadioStation.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<RadioStation>> _fetchStationsByTag(String tag,
      {int limit = 20}) async {
    final uri = Uri.https(_baseUrl, '/json/stations/bytag/$tag', {
      'order': 'clickcount',
      'reverse': 'true',
      'limit': limit.toString(),
      'hidebroken': 'true',
    });

    try {
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => RadioStation.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  String _removeAccents(String input) {
    const withAccents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const withoutAccents = 'aeiouunAEIOUUN';
    for (int i = 0; i < withAccents.length; i++) {
      input = input.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return input;
  }
}
