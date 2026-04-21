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

import '../ui/playlists_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../l10n/app_localizations.dart';
import '../models/media_item.dart';
import '../providers/audio_player_provider.dart';
import '../providers/audio_provider.dart';
import '../ui/favorites_screen.dart';
import '../ui/now_playing_screen.dart';
import '../ui/radio_screen.dart';
import '../ui/search_screen.dart';
import '../ui/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentSongAsync = ref.watch(currentSongProvider);

    final List<Widget> screens = [
      const _HomeScreen(),
      const SearchScreen(),
      const FavoritesScreen(),
      const RadioScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: screens),
          ),
          currentSongAsync.when(
            data: (song) =>
                song != null ? const MiniPlayer() : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home), label: l10n.home),
          NavigationDestination(
              icon: const Icon(Icons.search), label: l10n.search),
          NavigationDestination(
              icon: const Icon(Icons.favorite), label: l10n.favorites),
          NavigationDestination(
              icon: const Icon(Icons.radio), label: l10n.radio),
          NavigationDestination(
              icon: const Icon(Icons.settings), label: l10n.settings),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN (con acceso a Playlists mediante un botón en AppBar)
// ─────────────────────────────────────────────────────────────────────────────
class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: 'Mis Playlists',
            onPressed: () {
              // Navegar a pantalla de playlists (la añadiremos después como pantalla independiente)
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlaylistsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: l10n.addLocalFiles,
            onPressed: () => _pickLocalFiles(ref, context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/OpenPlayer.png', width: 120, height: 120),
            const SizedBox(height: 20),
            Text(
              l10n.appTitle,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeSubtitle,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocalFiles(WidgetRef ref, BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'm4a', 'aac', 'ogg'],
    );

    if (result != null && result.files.isNotEmpty) {
      final items = result.files.map((file) {
        final path = file.path!;
        final name = file.name;
        final fileUrl = path.startsWith('file://') ? path : 'file:///$path';
        final sanitizedUrl = fileUrl.replaceAll('\\', '/');
        return MediaItem(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}-${file.name}',
          title: name,
          artist: 'Archivo local',
          url: sanitizedUrl,
          imageUrl: '',
          source: MediaSource.archive,
        );
      }).toList();

      ref.read(audioControllerProvider.notifier).loadPlaylist(items);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI PLAYER (funcional)
// ─────────────────────────────────────────────────────────────────────────────
class MiniPlayer extends ConsumerStatefulWidget {
  const MiniPlayer({super.key});

  @override
  ConsumerState<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  String _fmt(Duration? d) {
    if (d == null || d.isNegative) return "0:00";
    try {
      final minutes = d.inMinutes.remainder(60);
      final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
      return "$minutes:$seconds";
    } catch (e) {
      return "0:00";
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = ref.watch(currentSongProvider).value;
    final player = ref.watch(audioPlayerProvider);
    final controller = ref.read(audioControllerProvider.notifier);

    if (song == null) return const SizedBox.shrink();

    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        if (playing) {
          _rotateController.repeat();
        } else {
          _rotateController.stop();
        }

        return Material(
          elevation: 12,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
              );
            },
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final dur = player.duration ?? Duration.zero;
                      final double maxVal = dur.inMilliseconds.toDouble();
                      final double currVal = pos.inMilliseconds.toDouble();

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 4),
                              overlayShape: SliderComponentShape.noOverlay,
                            ),
                            child: Slider(
                              activeColor: Colors.indigoAccent,
                              max: maxVal > 0 ? maxVal : 1.0,
                              value:
                                  currVal.clamp(0.0, maxVal > 0 ? maxVal : 1.0),
                              onChanged: (v) => controller
                                  .seek(Duration(milliseconds: v.toInt())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(pos),
                                    style: const TextStyle(fontSize: 10)),
                                Text(_fmt(dur),
                                    style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: Row(
                      children: [
                        RotationTransition(
                          turns: _rotateController,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: CachedNetworkImage(
                              imageUrl: song.imageUrl,
                              width: 45,
                              height: 45,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Icon(Icons.album, size: 45),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.album, size: 45),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: controller.previous,
                        ),
                        IconButton(
                          iconSize: 35,
                          icon: Icon(
                              playing ? Icons.pause_circle : Icons.play_circle),
                          onPressed:
                              playing ? controller.pause : controller.play,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: controller.next,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
