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

// lib/providers/search_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../services/jamendo_service.dart';
import '../services/audius_service.dart';
//import '../services/archive_service.dart'; // Asumo que la clase se llama ArchiveService

// Estado de búsqueda
class SearchState {
  final List<MediaItem> results;
  final bool isLoading;
  final String? errorJamendo;
  final String? errorAudius;
  //final String? errorArchive;

  SearchState({
    this.results = const [],
    this.isLoading = false,
    this.errorJamendo,
    this.errorAudius,
    //this.errorArchive,
  });

  SearchState copyWith({
    List<MediaItem>? results,
    bool? isLoading,
    String? errorJamendo,
    String? errorAudius,
    //String? errorArchive,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorJamendo: errorJamendo ?? this.errorJamendo,
      errorAudius: errorAudius ?? this.errorAudius,
      //errorArchive: errorArchive ?? this.errorArchive,
    );
  }
}

// Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final JamendoService _jamendo = JamendoService();
  final AudiusService _audius = AudiusService();
  //final ArchiveService _archive = ArchiveService();

  SearchNotifier() : super(SearchState());

  Future<void> search(String query) async {
    if (query.trim().length < 3) {
      state = SearchState();
      return;
    }

    state = state.copyWith(isLoading: true, results: []);

    // Ejecutar todas las fuentes en paralelo con manejo individual de errores
    final results = await Future.wait([
      _jamendo.search(query).catchError((e) {
        state = state.copyWith(errorJamendo: e.toString());
        return <MediaItem>[];
      }),
      _audius.search(query).catchError((e) {
        state = state.copyWith(errorAudius: e.toString());
        return <MediaItem>[];
      }),
      //_archive.search(query).catchError((e) {
      //state = state.copyWith(errorArchive: e.toString());
      //return <MediaItem>[];
      //}),
    ]);

    final allItems = results.expand((list) => list).toList();

    state = state.copyWith(results: allItems, isLoading: false);
  }
}

// Providers
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier();
});

final searchQueryProvider = StateProvider<String>((ref) => '');
