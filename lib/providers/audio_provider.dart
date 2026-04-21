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

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/media_item.dart';
import 'audio_player_provider.dart';

class AudioNotifier extends StateNotifier<AsyncValue<void>> {
  final AudioPlayer _player;

  AudioNotifier(this._player) : super(const AsyncValue.data(null));

  static const Map<String, String> _commonHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  Map<String, String> _headersForItem(MediaItem item) {
    if (item.id.startsWith('arc-')) {
      return {
        ..._commonHeaders,
        'Referer': 'https://archive.org/',
        'Origin': 'https://archive.org',
      };
    }
    if (item.id.startsWith('aud-')) {
      return {
        ..._commonHeaders,
        'Referer': 'https://audius.co/',
        'Origin': 'https://audius.co',
      };
    }
    return _commonHeaders;
  }

  Future<void> loadPlaylist(List<MediaItem> items,
      {int initialIndex = 0}) async {
    state = const AsyncValue.loading();
    try {
      final validItems = items.where((item) {
        final url = item.url.trim();
        return url.isNotEmpty &&
            (url.startsWith('http://') ||
                url.startsWith('https://') ||
                url.startsWith('file://'));
      }).toList();

      if (validItems.isEmpty) {
        state =
            AsyncValue.error('No hay pistas reproducibles', StackTrace.current);
        return;
      }

      final audioSources = validItems.map((item) {
        if (item.url.startsWith('file://')) {
          return AudioSource.uri(Uri.parse(item.url), tag: item);
        } else {
          return AudioSource.uri(
            Uri.parse(item.url),
            tag: item,
            headers: _headersForItem(item),
          );
        }
      }).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);

      await _player.setAudioSource(
        playlist,
        initialIndex: initialIndex.clamp(0, validItems.length - 1),
        initialPosition: Duration.zero,
      );

      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.ready) {
          _player.play();
        }
      });

      _player.play();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('❌ Error al cargar playlist: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  void play() => _player.play();
  void pause() => _player.pause();
  void next() => _player.seekToNext();
  void previous() => _player.seekToPrevious();
  void seek(Duration position) => _player.seek(position);
  void toggleShuffle() =>
      _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
  void toggleRepeat() {
    final mode = _player.loopMode == LoopMode.off
        ? LoopMode.one
        : _player.loopMode == LoopMode.one
            ? LoopMode.all
            : LoopMode.off;
    _player.setLoopMode(mode);
  }
}

final audioControllerProvider =
    StateNotifierProvider<AudioNotifier, AsyncValue<void>>((ref) {
  return AudioNotifier(ref.watch(audioPlayerProvider));
});

final currentSongProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioPlayerProvider).sequenceStateStream.map((state) {
    return state?.currentSource?.tag as MediaItem?;
  });
});
