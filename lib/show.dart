import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:miteru/watch.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:text_scroll/text_scroll.dart';

const sourceTypes = {
  "Default": "m3u8",
  "Sak": "mp4",
  "Kir": "mp4",
  "Default B": "mp4",
  // "Ac": "m3u8", // not working
  "S-mp4": "mp4",
  "Uv-mp4": "mp4",
  "Luf-mp4": "m3u8",
};

class ShowOverview extends StatefulWidget {
  final dynamic showData;
  const ShowOverview({super.key, required this.showData});

  @override
  State<ShowOverview> createState() => _ShowOverviewState();
}

class _ShowOverviewState extends State<ShowOverview> {
  @override
  Widget build(BuildContext context) {
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
                        ? buildEpisodeList(
                            context,
                            "sub",
                            "Sub",
                            Icons.subtitles,
                          )
                        : Container(),
                    lastEpisode()["dub"] != null
                        ? buildEpisodeList(
                            context,
                            "dub",
                            "Dub",
                            Icons.record_voice_over,
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

  Padding buildEpisodeList(
    BuildContext context,
    String translationType,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ExpansionTile(
        title: Text(title),
        children: List.generate(
          lastEpisode()[translationType],
          (index) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                icon: Icon(icon),
                label: Text("Episode ${index + 1}"),
                onPressed: () {
                  showSelectServerDialog(
                    context,
                    widget.showData["_id"],
                    translationType,
                    (index + 1).toString(),
                    (context, source) {
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
                  );
                },
              ),
              // const VerticalDivider(),
              TextButton.icon(
                onPressed: () {
                  showSelectServerDialog(
                    context,
                    widget.showData["_id"],
                    translationType,
                    (index + 1).toString(),
                    onlyType: "mp4",
                    (_, source) async {
                      final waitingSB =
                          ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Extracting source...."),
                        ),
                      );
                      final sourceURL = await extractSource(source);
                      waitingSB.close();

                      Dio().download(
                        sourceURL,
                        "${(await getDownloadsDirectory())!.path}"
                        "/Miteru/Downloads/${widget.showData["_id"]}"
                        "/$translationType/$index.mp4",
                        onReceiveProgress: (count, total) {
                          //
                        },
                        options: Options(),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Text("Download Started! "),
                              const VerticalDivider(),
                              TextButton(
                                onPressed: () {
                                  // TODO: Add on download start view downloads button
                                },
                                child: const Text(
                                  "Show Downloads",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                // child: const Row(
                //   children: [
                //     Text("Download"),
                //     Icon(Icons.download_outlined),
                //   ],
                // ),
                label: const Text("Download"),
                icon: const Icon(Icons.download_outlined),
              ),
            ],
          ),
        ),
      ),
    );
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
      String episodeString,
      void Function(BuildContext context, dynamic source) onSelect,
      {String? onlyType}) {
    return showDialog(
      context: context,
      builder: (contex) {
        return SimpleDialog(title: const Text("Select Server:"), children: [
          FutureBuilder(
            future: http.get(Uri.parse(
                'https://api.allanime.to/allanimeapi?variables={%22showId%22:%22$showId%22,%22translationType%22:%22$translationType%22,%22episodeString%22:%22$episodeString%22}&query=query%20(\$showId:%20String!,%20\$translationType:%20VaildTranslationTypeEnumType!,%20\$episodeString:%20String!)%20{%20%20%20%20episode(%20%20%20%20%20%20%20%20showId:%20\$showId%20%20%20%20%20%20%20%20translationType:%20\$translationType%20%20%20%20%20%20%20%20episodeString:%20\$episodeString%20%20%20%20)%20{%20%20%20%20%20%20%20%20episodeString%20sourceUrls%20%20%20%20}}')),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final sources = jsonDecode(snapshot.data!.body)["data"]
                    ["episode"]["sourceUrls"] as List;
                sources.removeWhere((source) =>
                    !sourceTypes.keys.contains(source["sourceName"]));
                if (onlyType != null) {
                  sources.removeWhere(
                    (source) => sourceTypes[source["sourceName"]] != onlyType,
                  );
                }
                return Column(
                  children: sources
                      .map(
                        (source) => TextButton(
                          onPressed: () {
                            onSelect(context, source);
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
        ]);
      },
    );
  }
}
