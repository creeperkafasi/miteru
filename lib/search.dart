import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

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
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text("Start typing to see results..."));
    }
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
          return ListView.builder(
            itemBuilder: (context, index) {
              return Padding(
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
                            items[index]["englishName"] ?? items[index]["name"],
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
                                          items[index]["season"]["year"]
                                              .toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w200,
                                      ),
                                    )
                                  : Container(),
                              VerticalDivider(),
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
              );
              // return Text(items[index].innerHtml);
            },
            itemCount: items.length,
          );
        } else if (snapshot.hasError) {
          return Center(
            child: ErrorWidget(snapshot.error!),
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
