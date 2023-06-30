import 'dart:convert';

import 'package:miteru/search.dart';
import 'package:miteru/utils/allanime.dart';
import 'package:miteru/watch.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:text_scroll/text_scroll.dart';

const allowedSourceNames = [
  "Default",
  "Sak",
  "Kir",
  "Default B",
  "Ac",
  "S-mp4",
  "Uv-mp4",
  "Luf-mp4",
];

class ShowOverview extends StatefulWidget {
  final dynamic showData;
  const ShowOverview({super.key, required this.showData});

  @override
  State<ShowOverview> createState() => _ShowOverviewState();
}

class _ShowOverviewState extends State<ShowOverview> {
  @override
  Widget build(BuildContext context) {
    print(widget.showData);
    return Scaffold(
        appBar: AppBar(
          title: SizedBox(
            height: 32,
            child: TextScroll(
              widget.showData["name"],
              velocity: const Velocity(pixelsPerSecond: Offset(20, 0)),
              delayBefore: const Duration(seconds: 1),
              fadedBorder: true,
              fadedBorderWidth: 0.05,
              pauseBetween: const Duration(seconds: 2),
              intervalSpaces: 10,
            ),
          ),
          bottomOpacity: 0.0,
        ),
        // extendBodyBehindAppBar: true,
        body: FutureBuilder(
          future: http.get(
            Uri.parse("https://allanime.to/anime/${widget.showData["_id"]}"),
            headers: {"Referer": "https://allanime.to"},
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final body = HtmlParser(snapshot.data!.body).parse();
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    body.querySelector("img.bg-banner") != null
                        ? Image.network(
                            body
                                .querySelector("img.bg-banner")!
                                .attributes["src"]!,
                          )
                        : Container(),
                    body.querySelector(".article-description") != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              initiallyExpanded: true,
                              childrenPadding:
                                  const EdgeInsets.only(bottom: 6.0),
                              title: const Text("Description"),
                              children: [
                                Card(
                                  elevation: 4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(body
                                        .querySelector(".article-description")!
                                        .text),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    lastEpisode()["sub"] != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: const Text("Sub"),
                              children: List.generate(
                                lastEpisode()["sub"],
                                (index) => TextButton.icon(
                                  icon: const Icon(Icons.subtitles),
                                  label: Text("Episode ${index + 1}"),
                                  onPressed: () {
                                    showSelectServerDialog(
                                      context,
                                      widget.showData["_id"],
                                      "sub",
                                      index + 1,
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    lastEpisode()["dub"] != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: const Text("Dub"),
                              children: List.generate(
                                lastEpisode()["dub"],
                                (index) => TextButton.icon(
                                  icon: const Icon(Icons.record_voice_over),
                                  label: Text("Episode ${index + 1}"),
                                  onPressed: () {
                                    showSelectServerDialog(
                                      context,
                                      widget.showData["_id"],
                                      "dub",
                                      index + 1,
                                    );
                                  },
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ));
  }

  lastEpisode() {
    if (widget.showData["lastEpisodeInfo"] != null) {
      return {
        "sub": int.tryParse(
          (widget.showData["lastEpisodeInfo"]["sub"]?["episodeString"])
              .toString(),
        ),
        "dub": int.tryParse(
          (widget.showData["lastEpisodeInfo"]["dub"]?["episodeString"])
              .toString(),
        ),
      };
    }

    return widget.showData["availableEpisodes"] ??
        {
          "sub": null,
          "dub": null,
        };
  }

  Future<dynamic> showSelectServerDialog(
    BuildContext context,
    String showId,
    String translationType,
    int episodeString,
  ) {
    return showDialog(
      context: context,
      builder: (contex) =>
          SimpleDialog(title: const Text("Select Server:"), children: [
        FutureBuilder(
          future: AllanimeAPI.episodeInfo(
            showId,
            episodeString,
            translationType,
          ),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final sources =
                  snapshot.data!["data"]["episode"]["sourceUrls"] as List;
              sources.removeWhere((source) =>
                  !allowedSourceNames.contains(source["sourceName"]));
              return Column(
                children: sources
                    .map(
                      (source) => TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WatchPage(
                                  source: source,
                                  showData: widget.showData,
                                ),
                              ));
                        },
                        child: Text(source["sourceName"]),
                      ),
                    )
                    .toList(),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ]),
    );
  }
}
