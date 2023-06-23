import 'dart:convert';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

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
                      final sourceUrl = Uri.parse(
                        "https://allanimenews.com${hexToAscii(widget.source["sourceUrl"].toString().split("#")[1]).replaceFirst("clock", "clock.json")}",
                      );
                      final source = await http.get(sourceUrl);
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
