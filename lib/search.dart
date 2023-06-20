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
    return FutureBuilder(
      future: http.get(Uri.parse(
          "https://9anime.to/ajax/anime/search?keyword=${Uri.encodeComponent(query)}")),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = jsonDecode(snapshot.data!.body);
          final items = HtmlParser(data["result"]["html"])
              .parse()
              .querySelectorAll(".item");
          return ListView.builder(
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.network(items[index]
                          .querySelector("img")!
                          .attributes["src"]!),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[index].querySelector(".name")!.innerHtml,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            items[index]
                                .querySelector(".name")!
                                .attributes["data-jp"]!,
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
                              const Icon(
                                Icons.star_border,
                                color: Colors.black26,
                              ),
                              Text(
                                items[index]
                                    .querySelector(".text-gray2")!
                                    .innerHtml
                                    .split('</i>')[1],
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
