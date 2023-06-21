import 'dart:convert';

import 'package:miteru/show.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:miteru/utils/db.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AnimeSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
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
    });
    return FutureBuilder(
      future: http.get(
        Uri.parse(
          'https://api.allanime.to/allanimeapi'
          '?variables={"search":{"query":"$query"}}'
          '&extensions={"persistedQuery":{"version":1,"sha256Hash":"06327bc10dd682e1ee7e07b6db9c16e9ad2fd56c1b769e47513128cd5c9fc77a"}}',
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = jsonDecode(snapshot.data!.body);
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
                        child: Image.network(
                          items[index]["thumbnail"] ??
                              "https://placehold.co/64x108/png?text=?",
                          height: 108,
                          width: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.network(
                                  "https://placehold.co/64x108/png?text=?"),
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
                            icon: Icon(Icons.close),
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
