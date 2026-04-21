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
import 'package:just_audio/just_audio.dart';
import '../models/media_item.dart';
import '../providers/audio_player_provider.dart';
import '../providers/audio_provider.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(currentSongProvider);
    final player = ref.watch(audioPlayerProvider);
    final controller = ref.read(audioControllerProvider.notifier);

    return songAsync.when(
      data: (song) {
        if (song == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('')),
            body: const Center(child: Text('Nada reproduciéndose')),
          );
        }

        // Gradiente basado en el tema (indigo + negro)
        final gradientColors = [
          Theme.of(context).colorScheme.primary.withOpacity(0.8),
          Theme.of(context).colorScheme.secondary.withOpacity(0.6),
          Colors.black87,
        ];

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: _SourceBadge(source: song.source),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Spacer(flex: 1),
                              _buildArtwork(song, player),
                              const Spacer(flex: 1),
                              _buildSongInfo(song),
                              const SizedBox(height: 24),
                              _buildProgressBar(player, controller),
                              const SizedBox(height: 24),
                              _buildMainControls(player, controller),
                              const SizedBox(height: 16),
                              _buildVolumeControl(player),
                              const SizedBox(height: 16),
                              _buildSecondaryControls(player, controller),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildArtwork(MediaItem song, AudioPlayer player) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        if (playing) {
          _rotateController.repeat();
        } else {
          _rotateController.stop();
        }

        return RotationTransition(
          turns: _rotateController,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: song.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child:
                      const Icon(Icons.album, size: 100, color: Colors.white54),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.broken_image,
                      size: 100, color: Colors.white54),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSongInfo(MediaItem song) {
    return Column(
      children: [
        Text(
          song.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar(AudioPlayer player, AudioNotifier controller) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      builder: (context, positionSnap) {
        final position = positionSnap.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.2),
              ),
              child: Slider(
                min: 0,
                max: duration.inMilliseconds.toDouble(),
                value: position.inMilliseconds
                    .toDouble()
                    .clamp(0, duration.inMilliseconds.toDouble()),
                onChanged: (value) =>
                    controller.seek(Duration(milliseconds: value.toInt())),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return '0:00';
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildMainControls(AudioPlayer player, AudioNotifier controller) {
    return StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.skip_previous, color: Colors.white),
              onPressed: controller.previous,
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: IconButton(
                iconSize: 72,
                icon: Icon(
                  playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                ),
                onPressed: playing ? controller.pause : controller.play,
              ),
            ),
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.skip_next, color: Colors.white),
              onPressed: controller.next,
            ),
          ],
        );
      },
    );
  }

  Widget _buildVolumeControl(AudioPlayer player) {
    return StreamBuilder<double>(
      stream: player.volumeStream,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 1.0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_down, color: Colors.white70, size: 20),
            SizedBox(
              width: 120,
              child: Slider(
                value: volume,
                onChanged: (value) => player.setVolume(value),
                activeColor: Colors.white,
                inactiveColor: Colors.white30,
              ),
            ),
            const Icon(Icons.volume_up, color: Colors.white70, size: 20),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryControls(AudioPlayer player, AudioNotifier controller) {
    return StreamBuilder<LoopMode>(
      stream: player.loopModeStream,
      builder: (context, loopSnap) {
        final loopMode = loopSnap.data ?? LoopMode.off;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                player.shuffleModeEnabled ? Icons.shuffle_on : Icons.shuffle,
                color: player.shuffleModeEnabled
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
              onPressed: controller.toggleShuffle,
            ),
            IconButton(
              icon: Icon(
                loopMode == LoopMode.one
                    ? Icons.repeat_one
                    : loopMode == LoopMode.all
                        ? Icons.repeat
                        : Icons.repeat,
                color: loopMode != LoopMode.off
                    ? Colors.white
                    : Colors.white.withOpacity(0.5),
              ),
              onPressed: controller.toggleRepeat,
            ),
          ],
        );
      },
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final MediaSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;
    switch (source) {
      case MediaSource.jamendo:
        icon = Icons.library_music;
        color = Colors.blue;
        label = 'Jamendo';
        break;
      case MediaSource.audius:
        icon = Icons.cloud;
        color = Colors.purple;
        label = 'Audius';
        break;
      case MediaSource.archive:
        icon = Icons.archive;
        color = Colors.brown;
        label = 'Archive';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
