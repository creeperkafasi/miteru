import 'dart:ui';

import 'package:miteru/utils/allanime.dart';
import 'package:miteru/watch.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';

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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        bottomOpacity: 0.0,
      ),
      body: SingleChildScrollView(
        child: FutureBuilder(
          future: AllanimeAPI.showInfo(widget.showData["_id"]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final showInfo = snapshot.data!["data"]["show"];
              return Stack(
                children: [
                  showInfo["banner"] != null
                      ? ImageFiltered(
                          imageFilter:
                              ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                          child: ShaderMask(
                            shaderCallback: (rect) {
                              return LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ).createShader(
                                  Rect.fromLTRB(0, 0, rect.width, rect.height));
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image.network(
                              showInfo["banner"],
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.network(
                                "https://placehold.co/64x108/png?text=?",
                              ),
                            ),
                          ),
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.only(top: 48.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 8,
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  showInfo["thumbnail"],
                                  height: 180,
                                ),
                              ),
                              Expanded(
                                child: SizedBox(
                                  // height: 180,
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            widget.showData["englishName"] ??
                                                widget.showData["name"],
                                            // maxLines: 2,
                                            textAlign: TextAlign.center,
                                            // overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        showInfo["nativeName"] != null
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                  showInfo["nativeName"],
                                                  // maxLines: 2,
                                                  // overflow:
                                                  //     TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w200,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              )
                                            : Container(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              // ignore: unnecessary_cast
                              const SizedBox(
                                width: 12.0,
                              ) as Widget
                            ]
                                .followedBy(
                                  (showInfo["genres"] as List).map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Chip(
                                        elevation: 3,
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                        ),
                                        label: Text(e.toString()),
                                        shadowColor: Colors.black,
                                        padding: const EdgeInsets.all(
                                          0.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        showInfo["description"] != null
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0, vertical: 4.0),
                                child: Card(
                                  elevation: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: ExpansionTile(
                                      title: const Text("Description"),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: Text(
                                            // Description returned by the api
                                            // is html encoded and needs to be
                                            // parsed before using
                                            parseFragment(
                                              showInfo["description"]
                                                  .toString(),
                                            ).text!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : Container(),
                        // const Divider(),
                        episodesWidgetBuilder(showInfo, context),
                      ],
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return ErrorWidget(snapshot.error!);
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Padding episodesWidgetBuilder(showInfo, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Card(
        elevation: 2,
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Watch Now",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const Divider(),
              const TabBar(
                tabs: [
                  Tab(child: Text("Sub")),
                  Tab(child: Text("Dub")),
                  Tab(child: Text("Raw")),
                ],
              ),
              SizedBox(
                height: 360,
                child: TabBarView(
                  children: ["sub", "dub", "raw"]
                      .map(
                        (tl) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: (showInfo["availableEpisodesDetail"][tl]
                                      as List)
                                  .reversed
                                  .map(
                                    (episode) => TextButton.icon(
                                      onPressed: () => showSelectServerDialog(
                                        context,
                                        showInfo["_id"],
                                        tl,
                                        episode,
                                      ),
                                      icon: Icon({
                                        "sub": Icons.subtitles_outlined,
                                        "dub": Icons.record_voice_over_outlined,
                                        "raw": Icons.cleaning_services_outlined,
                                      }[tl]),
                                      label: Text(
                                        "Episode "
                                        "$episode",
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> showSelectServerDialog(
    BuildContext context,
    String showId,
    String translationType,
    String episodeString,
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
