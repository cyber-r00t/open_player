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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/radio_station.dart';
import '../providers/audio_provider.dart';
import '../providers/radio_provider.dart';
import '../models/media_item.dart';

class RadioScreen extends ConsumerStatefulWidget {
  const RadioScreen({super.key});

  @override
  ConsumerState<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends ConsumerState<RadioScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(radioSearchQueryProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(radioSearchProvider);
    final query = ref.watch(radioSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Buscar emisoras...',
            border: InputBorder.none,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: stationsAsync.when(
        data: (stations) {
          if (stations.isEmpty) {
            return const Center(child: Text('No se encontraron emisoras'));
          }
          return ListView.builder(
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return _StationTile(station: station);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _StationTile extends ConsumerWidget {
  final RadioStation station;

  const _StationTile({required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: _StationIcon(station: station),
        title: Text(station.name),
        subtitle: Text('${station.country} • ${station.bitrate} kbps'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (station.clickCount > 0)
              Text(
                '👂 ${_formatClicks(station.clickCount)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playStation(ref),
            ),
          ],
        ),
        onTap: () => _playStation(ref),
      ),
    );
  }

  void _playStation(WidgetRef ref) {
    // Convertimos la emisora en un MediaItem especial (source: radio)
    final mediaItem = MediaItem(
      id: 'radio-${station.id}',
      title: station.name,
      artist: station.country,
      url: station.url,
      imageUrl: station.favicon ?? '',
      source: MediaSource
          .archive, // Reutilizamos el enum o podríamos crear MediaSource.radio
    );
    ref.read(audioControllerProvider.notifier).loadPlaylist([mediaItem]);
  }

  String _formatClicks(int clicks) {
    if (clicks >= 1000000) {
      return '${(clicks / 1000000).toStringAsFixed(1)}M';
    }
    if (clicks >= 1000) {
      return '${(clicks / 1000).toStringAsFixed(0)}K';
    }
    return clicks.toString();
  }
}

class _StationIcon extends StatelessWidget {
  final RadioStation station;

  const _StationIcon({required this.station});

  @override
  Widget build(BuildContext context) {
    if (station.favicon != null && station.favicon!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: station.favicon!,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (_, __) => const Icon(Icons.radio),
        errorWidget: (_, __, ___) => const Icon(Icons.radio),
      );
    }
    return Container(
      width: 50,
      height: 50,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Icon(Icons.radio),
    );
  }
}
