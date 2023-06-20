import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:text_scroll/text_scroll.dart';

class ShowOverview extends StatefulWidget {
  final dynamic showData;
  const ShowOverview({super.key, this.showData});

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
              velocity: Velocity(pixelsPerSecond: Offset(20, 0)),
              delayBefore: Duration(seconds: 1),
              fadedBorder: true,
              fadedBorderWidth: 0.05,
              pauseBetween: Duration(seconds: 2),
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
                              childrenPadding: EdgeInsets.only(bottom: 6.0),
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
                    widget.showData["lastEpisodeInfo"]["sub"] != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: Text("Sub"),
                              children: List.generate(
                                int.parse(widget.showData["lastEpisodeInfo"]
                                    ["sub"]["episodeString"]),
                                (index) => TextButton.icon(
                                  icon: const Icon(Icons.subtitles),
                                  label:
                                      Text("Episode " + (index + 1).toString()),
                                  onPressed: () {},
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    widget.showData["lastEpisodeInfo"]["dub"] != null
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ExpansionTile(
                              title: Text("Dub"),
                              children: List.generate(
                                int.parse(widget.showData["lastEpisodeInfo"]
                                    ["dub"]["episodeString"]),
                                (index) => TextButton.icon(
                                  icon: const Icon(Icons.record_voice_over),
                                  label:
                                      Text("Episode " + (index + 1).toString()),
                                  onPressed: () {},
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
}
