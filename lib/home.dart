import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:miteru/search.dart';
import 'package:miteru/show.dart';
import 'package:miteru/trackers.dart';
import 'package:miteru/utils/allanime.dart';
import 'package:miteru/utils/kitsu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.refreshFunc,
  });

  final VoidCallback refreshFunc;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        const CharacterActivator("f", control: true): VoidCallbackIntent(
          () => showSearch(context: context, delegate: AnimeSearchDelegate()),
        ),
      },
      child: Focus(
        autofocus: true,
        child: Builder(builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Miteru"),
              actions: [
                Builder(builder: (context) {
                  final brightness = Theme.of(context).brightness;
                  return IconButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        prefs.setBool("brightness",
                            !(prefs.getBool("brightness") ?? true));
                        widget.refreshFunc();
                      });
                    },
                    icon: Icon(
                      (brightness == Brightness.dark)
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                  );
                }),
                IconButton(
                  onPressed: () {
                    showSearch(
                        context: context, delegate: AnimeSearchDelegate());
                  },
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            drawer: Drawer(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          "見てる",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackingScreen(),
                        ),
                      ),
                      label: const Text("Tracking"),
                      icon: const Icon(Icons.remove_red_eye_outlined),
                    ),
                  ],
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                children: [
                  HomePageShelf(
                    title: "Popular Today",
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    color: Colors.pink,
                    shelfItems: Future.sync(() async {
                      final resJson = await AllanimeAPI.queryPopular();
                      return (resJson["data"]["queryPopular"]["recommendations"]
                              as List)
                          .map(
                            (e) => InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ShowOverview(showData: e["anyCard"]),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.network(
                                          e["anyCard"]["thumbnail"],
                                          height: 130,
                                        ),
                                      ),
                                      Text(
                                        (e["anyCard"]["englishName"] ??
                                                e["anyCard"]["name"])
                                            .toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList();
                    }),
                  ),
                  HomePageShelf(
                    title: "Recent Uploads",
                    icon: const Icon(Icons.history),
                    color: Colors.lime,
                    shelfItems: Future.sync(() async {
                      // Searching with an empty query returns all shows sorted by recent
                      final items =
                          (await AllanimeAPI.search("", origin: "JP"))["data"]
                              ["shows"]["edges"] as List;
                      // Filter out the garbage
                      items.removeWhere(
                        (element) =>
                            (double.parse((element["score"] ?? 0).toString()) <=
                                6.5),
                      );
                      return (items)
                          .map(
                            (e) => InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ShowOverview(showData: e),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        child: Image.network(
                                          e["thumbnail"],
                                          height: 130,
                                        ),
                                      ),
                                      Text(
                                        (e["englishName"] ?? e["name"])
                                            .toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList();
                    }),
                  ),
                  HomePageShelf(
                    title: "Kitsu tracker",
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    shelfItems: Future.sync(() async {
                      final prefs = await SharedPreferences.getInstance();
                      if (prefs.getString("kitsu-User") == null) {
                        throw Exception("Kitsu user not set");
                      }
                      final lib = await KitsuApi.getUserLibrary(
                        prefs.getString("kitsu-User") ?? "",
                        filters: {
                          "status": "current",
                          "kind": "anime",
                        },
                      );
                      return (lib["data"] as List)
                          .map(
                            kitsuButton,
                          )
                          .toList();
                    }),
                    color: Colors.orange,
                    onErrorWidget: (error) => Container(
                      color:
                          Theme.of(context).colorScheme.error.withOpacity(0.5),
                      width: MediaQuery.of(context).size.width,
                      height: 168,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$error",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TrackingScreen(),
                                ),
                              ),
                              icon: const Icon(Icons.remove_red_eye_outlined),
                              label: const Text("Open Tracking Menu"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  FutureBuilder<dynamic> kitsuButton(e) => FutureBuilder(
        future: KitsuApi.getLibEntryAnimeDetails(e["id"]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final title = snapshot
                .data?["data"]?["attributes"]?["titles"].entries.first.value;
            return InkWell(
              onTap: title != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FutureBuilder(
                              future: AllanimeAPI.search(title),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final results =
                                      snapshot.data!["data"]["shows"]["edges"];
                                  if ((results as List).isEmpty) {
                                    Navigator.pop(context);
                                  }

                                  return ShowOverview(
                                    showData: results[0],
                                  );
                                }
                                return const Expanded(
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }),
                        ),
                      );
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 100,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          snapshot.data!["data"]["attributes"]["posterImage"]
                                  ["tiny"] ??
                              "https://placehold.co/90x130/png?text=?",
                          height: 130,
                        ),
                      ),
                      Text(
                        title ?? "",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Container();
        },
      );
}

class HomePageShelf extends StatefulWidget {
  final Future<List<Widget>> shelfItems;
  final String title;
  final Widget icon;
  final ColorSwatch color;

  final Widget Function(Object)? onErrorWidget;

  const HomePageShelf({
    super.key,
    required this.title,
    required this.icon,
    required this.shelfItems,
    required this.color,
    this.onErrorWidget,
  });

  @override
  State<HomePageShelf> createState() => _HomePageShelfState();
}

class _HomePageShelfState extends State<HomePageShelf> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                widget.icon,
                const VerticalDivider(),
                Text(widget.title, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          FutureBuilder<List<Widget>>(
            future: widget.shelfItems,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Scrollbar(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: scrollController,
                          child: Row(
                            children: snapshot.data!,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(
                        10,
                        (index) => Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Container(
                                  color: widget.color[index * 100 + 100],
                                  height: 140,
                                  width: 100,
                                ),
                              ),
                              const Text("Loading..."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  snapshot.hasError && widget.onErrorWidget != null
                      ? widget.onErrorWidget!(snapshot.error!)
                      : Text((snapshot.error ?? "").toString()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
