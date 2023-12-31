import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:miteru/show.dart';
import 'package:flutter/material.dart';
import 'package:miteru/utils/allanime.dart';
import 'package:miteru/utils/db.dart';

class AnimeSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
          showSuggestions(context);
        },
        icon: const Icon(Icons.close),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    Future.sync(() async {
      final db = await getAppDb();
      db.insert("SearchHistory", {
        "query": query,
        "searchtime": DateTime.now().toString(),
      });
      db.update(
        "SearchHistory",
        {
          "searchtime": DateTime.now().toString(),
        },
        where: "query = ?",
        whereArgs: [query],
      );
    });
    return FutureBuilder(
      future: AllanimeAPI.search(query),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final items = data["data"]["shows"]["edges"] as List;
          if (items.isEmpty) {
            return const Center(
              child: Text(
                "Nothing found!\nTry searching for something else",
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShowOverview(
                        showData: items[index],
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: CachedNetworkImage(
                          imageUrl: items[index]["thumbnail"] ??
                              "https://placehold.co/64x108/png?text=?",
                          height: 108,
                          width: 64,
                          fit: BoxFit.contain,
                          errorWidget: (context, error, stackTrace) =>
                              CachedNetworkImage(
                            imageUrl: "https://placehold.co/64x108/png?text=?",
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              items[index]["englishName"] ??
                                  items[index]["name"],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              items[index]["name"].toString(),
                              // overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w200,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            Row(
                              children: [
                                items[index]["season"] != null
                                    ? Text(
                                        items[index]["season"]["quarter"] +
                                            " " +
                                            items[index]["season"]["year"]
                                                .toString(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w200,
                                        ),
                                      )
                                    : Container(),
                                const VerticalDivider(),
                                const Icon(
                                  Icons.star_border,
                                  color: Colors.black26,
                                ),
                                Text(
                                  (items[index]["score"] ?? "?").toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w200,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
              // return Text(items[index].innerHtml);
            },
            itemCount: items.length,
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: ErrorWidget(snapshot.error!),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (kDebugMode) {
      return StatefulBuilder(builder: (context, setState) {
        return Stack(
          children: [
            buildHistory(context),
            // Positioned(
            //   bottom: 0,
            //   right: 0,
            //   child: TextButton(
            //     child: const Text("Debug Purge DB"),
            //     onPressed: () => setState(() {
            //       purgeTheDatabase();
            //     }),
            //   ),
            // ),
          ],
        );
      });
    }
    return buildHistory(context);
  }

  Widget buildHistory(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return FutureBuilder<List<Map<String, Object?>>>(
          future: Future.sync(() async {
            final db = await getAppDb();
            final history = await db.query("SearchHistory");
            db.close();
            return history;
          }),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              // using toList to make the list owned
              var history = snapshot.data!.toList();
              history.removeWhere(
                (element) => element["query"].toString() == "",
              );
              history.sort(
                (a, b) => -DateTime.parse(a["searchtime"].toString())
                    .compareTo(DateTime.parse(b["searchtime"].toString())),
              );
              // TODO: Replace with a fuzzy finder maybe
              history.removeWhere(
                (element) => !element["query"].toString().contains(query),
              );
              return ListView.builder(
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      query = history[index]["query"].toString();
                      showResults(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.history),
                          const VerticalDivider(),
                          Expanded(
                            child: Text(history[index]["query"].toString()),
                          ),
                          IconButton(
                            onPressed: () {
                              showDeleteDialog(
                                context,
                                history,
                                index,
                                setState,
                              );
                            },
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                itemCount: history.length,
              );
            }
            return Container();
          },
        );
      },
    );
  }

  Future<dynamic> showDeleteDialog(
    BuildContext context,
    List<Map<String, Object?>> history,
    int index,
    StateSetter setState,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure"),
        content: Text(
          "This will remove "
          "\"${history[index]["query"]}\" from your "
          "search history.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nevermind"),
          ),
          TextButton(
            onPressed: () {
              Future.sync(() async {
                final db = await getAppDb();
                await db.delete(
                  "SearchHistory",
                  where: "query = ?",
                  whereArgs: [history[index]["query"]],
                );
                await db.close();
                setState(() {});
              });

              Navigator.pop(context);
            },
            child: const Text("Yes."),
          ),
        ],
      ),
    );
  }
}
