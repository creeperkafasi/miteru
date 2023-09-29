import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:fvp/fvp.dart';
import 'package:miteru/home.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  registerWith();

  runApp(const AnimeApp());
}

class AnimeApp extends StatefulWidget {
  const AnimeApp({super.key});

  @override
  State<AnimeApp> createState() => _AnimeAppState();
}

class _AnimeAppState extends State<AnimeApp> {
  Brightness brightness = SchedulerBinding.instance.window.platformBrightness;

  @override
  void initState() {
    _loadSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const CharacterActivator("d", control: true):
            VoidCallbackIntent(() async {
          final prefs = await SharedPreferences.getInstance();
          prefs.setBool("brightness", !(prefs.getBool("brightness") ?? true));
          refresh();
        }),
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
      },
      title: "Miteru",
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      home: HomePage(refreshFunc: refresh),
    );
  }

  // Shitty global settings logic: themes, etc.
  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      brightness = prefs.getBool("brightness") ?? true
          ? Brightness.light
          : Brightness.dark;
    });
  }

  refresh() {
    setState(() {
      _loadSettings();
    });
  }
}
