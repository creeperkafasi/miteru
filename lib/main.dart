import 'dart:io';

import 'package:miteru/search.dart';
import 'package:flutter/material.dart';
import 'package:miteru/utils/db.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
  final db = await getAppDb();
  runApp(const AnimeApp());
}

class AnimeApp extends StatefulWidget {
  const AnimeApp({super.key});

  @override
  State<AnimeApp> createState() => _AnimeAppState();
}

class _AnimeAppState extends State<AnimeApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: "Miteru",
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Miteru"),
            actions: [
              IconButton(
                onPressed: () {
                  showSearch(context: context, delegate: AnimeSearchDelegate());
                },
                icon: const Icon(Icons.search),
              )
            ],
          ),
          body: Container(),
        );
      }),
    );
  }
}
