import 'dart:io';

import 'package:miteru/search.dart';
import 'package:flutter/material.dart';

 class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
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
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => const SearchPage(),
                  //   ),
                  // );
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
