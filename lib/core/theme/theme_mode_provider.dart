import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Global theme mode. Defaults to [ThemeMode.system] so the OS decides;
/// Settings can set it to light/dark explicitly.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
