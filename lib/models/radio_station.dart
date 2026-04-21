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

class RadioStation {
  final String id;
  final String name;
  final String country;
  final String language;
  final String url;
  final String? favicon;
  final List<String> tags;
  final int bitrate;
  final int clickCount;

  RadioStation({
    required this.id,
    required this.name,
    required this.country,
    required this.language,
    required this.url,
    this.favicon,
    required this.tags,
    required this.bitrate,
    required this.clickCount,
  });

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['stationuuid'] ?? '',
      name: json['name'] ?? 'Emisora desconocida',
      country: json['country'] ?? '',
      language: json['language'] ?? '',
      url: json['url_resolved'] ?? json['url'] ?? '',
      favicon: json['favicon'],
      tags: (json['tags'] as String? ?? '')
          .split(',')
          .map((e) => e.trim())
          .toList(),
      bitrate: json['bitrate'] ?? 0,
      clickCount: json['clickcount'] ?? 0,
    );
  }
}
