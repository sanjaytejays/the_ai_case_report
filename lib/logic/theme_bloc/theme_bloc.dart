import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState(themeMode: ThemeMode.system)) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode');

    if (isDark != null) {
      emit(ThemeState(themeMode: isDark ? ThemeMode.dark : ThemeMode.light));
    } else {
      emit(const ThemeState(themeMode: ThemeMode.system));
    }
  }

  Future<void> _onToggleTheme(
    ToggleTheme event,
    Emitter<ThemeState> emit,
  ) async {
    final mode = event.isDark ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeState(themeMode: mode));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', event.isDark);
  }
}
