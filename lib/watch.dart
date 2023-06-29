import 'dart:convert';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class WatchPage extends StatefulWidget {
  final dynamic source;
  final dynamic showData;
  const WatchPage({super.key, required this.source, required this.showData});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  VideoPlayerController? playerController;
  double aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
  }

  @override
  void dispose() {
    super.dispose();
    Wakelock.disable();
    playerController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
            color: Colors.black,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FutureBuilder(
              future: playerController != null
                  ? Future.value("Ok")
                  : Future.sync(() async {
                      final decryptedClockUrl = decryptAllAnime(
                        "1234567890123456789",
                        widget.source["sourceUrl"].toString().split("##")[1],
                      );
                      final sourceUrl = Uri.parse(
                        "https://allanimenews.com${decryptedClockUrl.replaceFirst("clock", "clock.json")}",
                      );
                      final source = await http.get(
                        sourceUrl,
                        headers: {"Referer": "https://allanime.to"},
                      );
                      final url = jsonDecode(source.body)["links"][0]["link"];
                      playerController = VideoPlayerController.network(url);
                      await playerController!.initialize();
                      aspectRatio = playerController!.value.aspectRatio;
                      return "Ok";
                    }),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Chewie(
                    controller: ChewieController(
                      videoPlayerController: playerController!,
                      aspectRatio: aspectRatio,
                      autoInitialize: true,
                      // autoPlay: true,
                      // fullScreenByDefault: true,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorWidget(snapshot.error!);
                }
                return const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      Text("Loading..."),
                    ],
                  ),
                );
              },
            )),
      ),
    );
  }
}

String hexToAscii(String hexString) => List.generate(
      hexString.length ~/ 2,
      (i) => String.fromCharCode(
          int.parse(hexString.substring(i * 2, (i * 2) + 2), radix: 16)),
    ).join();

// Allanime XOR cipher

String decryptAllAnime(String password, String target) {
  List<int> data = _hexToBytes(target);

  Iterable<String> genexp() sync* {
    for (int segment in data) {
      for (int i = 0; i < password.length; i++) {
        segment ^= password.codeUnitAt(i);
      }
      yield String.fromCharCode(segment);
    }
  }

  return genexp().join();
}

List<int> _hexToBytes(String hexString) {
  List<int> bytes = [];
  for (int i = 0; i < hexString.length; i += 2) {
    String hex = hexString.substring(i, i + 2);
    int byteValue = int.parse(hex, radix: 16);
    bytes.add(byteValue);
  }
  return bytes;
}
