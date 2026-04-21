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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();

  // ✅ Configuramos el modo de bucle por defecto para mantener el motor alerta
  player.setLoopMode(LoopMode.all);

  return player;
});
