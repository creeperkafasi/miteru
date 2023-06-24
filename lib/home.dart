import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:miteru/search.dart';
import 'package:http/http.dart' as http;
import 'package:miteru/show.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        HomePageShelf(
          title: "Popular Today",
          icon: const Icon(Icons.emoji_emotions_outlined),
          color: Colors.pink,
          shelfItems: Future.sync(() async {
            // await Future.delayed(const Duration(seconds: 2));
            final res = await http.get(Uri.parse(
              'https://api.allanime.to/allanimeapi?variables={"type":"anime","size":20,"dateRange":1,"page":1,"allowAdult":false,"allowUnknown":false}&extensions={"persistedQuery":{"version":1,"sha256Hash":"1fc9651b0d4c3b9dfd2fa6e1d50b8f4d11ce37f988c23b8ee20f82159f7c1147"}}',
            ));
            final resJson = jsonDecode(res.body);
            return (resJson["data"]["queryPopular"]["recommendations"] as List)
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
                              borderRadius: BorderRadius.circular(8.0),
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
            // await Future.delayed(const Duration(seconds: 2));
            final res = await http.get(Uri.parse(
              'https://api.allanime.to/allanimeapi?variables={%22search%22:{},%22limit%22:26,%22page%22:1,%22translationType%22:%22sub%22,%22countryOrigin%22:%22JP%22}&extensions={%22persistedQuery%22:{%22version%22:1,%22sha256Hash%22:%2206327bc10dd682e1ee7e07b6db9c16e9ad2fd56c1b769e47513128cd5c9fc77a%22}}',
            ));
            final items =
                jsonDecode(res.body)["data"]["shows"]["edges"] as List;
            items.removeWhere(
              // filter out the garbage
              (element) =>
                  (double.parse((element["score"] ?? 0).toString()) <= 6.5),
            );
            return (items)
                .map(
                  (e) => InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShowOverview(showData: e),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: 100,
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                e["thumbnail"],
                                height: 130,
                              ),
                            ),
                            Text(
                              (e["englishName"] ?? e["name"]).toString(),
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
      ],
    );
  }
}

class HomePageShelf extends StatelessWidget {
  final Future<List<Widget>> shelfItems;
  final String title;
  final Widget icon;
  final ColorSwatch color;

  const HomePageShelf({
    super.key,
    required this.title,
    required this.icon,
    required this.shelfItems,
    required this.color,
  });

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
                icon,
                const VerticalDivider(),
                Text(title, style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
          FutureBuilder<List<Widget>>(
            future: shelfItems,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: snapshot.data!,
                  ),
                );
              }
              if (snapshot.hasError) {
                print(snapshot.error);
              }
              return SingleChildScrollView(
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
                              color: color[index * 100 + 100],
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
              );
            },
          ),
        ],
      ),
    );
  }
}
