import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class WatchPage extends StatefulWidget {
  final dynamic source;
  final dynamic showData;
  const WatchPage({super.key, required this.source, required this.showData});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text("Watch ${widget.showData["name"]}"),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.red,
          child: FutureBuilder(
            future: widget.source["sourceUrl"].toString().startsWith("#")
                ? Future.sync(() async {
                    final source = await http.get(
                      Uri.parse(
                        "https://allanimenews.com${hexToAscii(widget.source["sourceUrl"].toString().split("#")[1]).replaceFirst("clock", "clock.json")}",
                      ),
                    );
                    return jsonDecode(source.body)["links"][0]["link"];
                  })
                : Future.value(widget.source["sourceUrl"].toString()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                // TODO: Replace the webview with a video player like chewie
                return InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(snapshot.data),
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          )),
    );
  }
}

String hexToAscii(String hexString) => List.generate(
      hexString.length ~/ 2,
      (i) => String.fromCharCode(
          int.parse(hexString.substring(i * 2, (i * 2) + 2), radix: 16)),
    ).join();
