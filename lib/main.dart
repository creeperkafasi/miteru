import 'dart:convert';
import 'dart:io';

import 'package:miteru/home.dart';
import 'package:flutter/material.dart';
import 'package:miteru/search.dart';
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
      routes: {
        "home": (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Miteru"),
              actions: [
                IconButton(
                  onPressed: () {
                    showSearch(
                        context: context, delegate: AnimeSearchDelegate());
                  },
                  icon: const Icon(Icons.search),
                )
              ],
            ),
            drawer: const AppDrawer(),
            body: const HomePage(),
          );
        },
      },
      initialRoute: "home",
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Miteru",
                style: TextStyle(
                  color: Colors.pinkAccent[700],
                  fontWeight: FontWeight.w800,
                  fontSize: 48,
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                onPressed: null,
                label: const Text("Downloads"),
                icon: const Icon(Icons.download),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextButton.icon(
                onPressed: null,
                label: const Text("Library"),
                icon: const Icon(Icons.bookmark),
              ),
            ),
            Expanded(child: Container()),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.star_rounded),
              label: const Text("Star Miteru on GitHub"),
            )
          ],
        ),
      ),
    );
  }
}
