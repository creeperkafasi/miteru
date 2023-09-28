import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:m3u_nullsafe/m3u_nullsafe.dart';

class AllanimeAPI {
  static const String allanimeBase = "https://allanime.to";
  static const String allanimeApiBase = "https://api.allanime.day/api";
  static const Map<String, String> headersBase = {"Referer": allanimeBase};

  static Future<Map> queryPopular() async {
    final res = await http.get(
      Uri.parse(
        "$allanimeApiBase"
        """?variables=
        {
          "type": "anime",
          "size": 20,
          "dateRange": 1
        }
        """
        """&query=
        query(\$type: VaildPopularTypeEnumType!, \$size: Int!, \$dateRange: Int) {
          queryPopular(type: \$type, size: \$size, dateRange: \$dateRange) {
            recommendations {
              anyCard {
                _id
                name
                englishName
                nativeName
                thumbnail
                availableEpisodes
              }
            }
          }
        }
        """,
      ),
      headers: headersBase,
    );
    return jsonDecode(res.body);
  }

  static Future<Map> search(String query, {String? origin}) async {
    final res = await http.get(
      Uri.parse(
        "$allanimeApiBase"
        """?variables=
        {
          "search": {
            "query": "$query"
          },
          "countryOrigin": "${origin ?? "ALL"}"
        }
        """
        """&query=
        query(\$search: SearchInput, \$countryOrigin: VaildCountryOriginEnumType) {
          shows(search: \$search, countryOrigin: \$countryOrigin) {
            edges {
              _id
              name
              nativeName
              englishName
              thumbnail
              score
              season
              availableEpisodes
            }
          }
        }
        """,
      ),
      headers: headersBase,
    );
    return jsonDecode(res.body);
  }

  static Future<Map> episodeInfo(
    String showId,
    String episode,
    String translationType,
  ) async {
    final res = await http.get(
      Uri.parse(
        "$allanimeApiBase"
        """?variables=
        {
          "showId": "$showId",
          "episodeString": "$episode",
          "translationType": "$translationType"
        }
        """
        """&query=
        query(
          \$showId: String!
          \$episodeString: String!
          \$translationType: VaildTranslationTypeEnumType!
        ) {
          episode(
            showId: \$showId
            episodeString: \$episodeString
            translationType: \$translationType
          ) {
            sourceUrls
            thumbnail
            notes
          }
        }
        """,
      ),
      headers: headersBase,
    );
    return jsonDecode(res.body);
  }

  static Future<Map> showInfo(
    String showId,
  ) async {
    final res = await http.get(
      Uri.parse(
        "$allanimeApiBase"
        """?variables=
        {
          "id": "$showId"
        }
        """
        """&query=
        query(\$id: String!) {
          show(_id: \$id) {
            _id
            name
            englishName
            nativeName
            airedEnd
            airedStart
            genres
            isAdult
            description
            banner
            thumbnail
            availableEpisodesDetail
          }
        }
        """,
      ),
      headers: headersBase,
    );
    return jsonDecode(res.body);
  }

  // Allanime XOR cipher
  static String decryptAllAnime(String password, String target) {
    List<int> data = _hexToBytes(target);

    Iterable<String> genexp() sync* {
      for (int segment in data) {
        for (int i = 0; i < password.length; i++) {
          segment ^= 56;
        }
        yield String.fromCharCode(segment);
      }
    }

    return genexp().join();
  }

  static List<int> _hexToBytes(String hexString) {
    List<int> bytes = [];
    for (int i = 0; i < hexString.length; i += 2) {
      String hex = hexString.substring(i, i + 2);
      int byteValue = int.parse(hex, radix: 16);
      bytes.add(byteValue);
    }
    return bytes;
  }

  static Future<List<Quality>> getQualitiesFromSource(
    dynamic src,
  ) async {
    final decryptedClockUrl = decryptAllAnime(
      "1234567890123456789",
      src["sourceUrl"].toString().split("--")[1],
    );
    final clockUrl = Uri.parse(
      "https://embed.ssbcontent.site${decryptedClockUrl.replaceFirst("clock", "clock.json")}",
    );
    final source = await http.get(
      clockUrl,
      headers: {"Referer": "https://allanime.to"},
    );

    List<Quality> qualities = [];
    for (var link in jsonDecode(source.body)["links"] as List) {
      if (link["hls"] != null) {
        if (link["link"].toString().contains("workfields")) continue;
        final m3u8Content = (await http.get(Uri.parse(link["link"]))).body;

        for (var q in (await M3uParser.parse(
          m3u8Content,
        ))) {
          var baseUrl = Uri.parse(link["link"]);
          List<String> newPathSegments = [];
          newPathSegments.addAll(baseUrl.pathSegments);
          newPathSegments.removeLast();
          newPathSegments.add(q.link);

          qualities.add(
            Quality(
              url: baseUrl.replace(pathSegments: newPathSegments),
              priority: 0,
              name: "${link['resolutionStr']} - "
                  "${RegExp(r"\d+p").firstMatch(q.title)?.group(0).toString() ?? q.title}",
            ),
          );
        }
      } else {
        qualities.add(Quality(
          url: Uri.parse(link["link"]),
          priority: link["priority"] ?? 0,
          name: "${src["sourceName"]} ${link["resolutionStr"]}",
        ));
      }
    }

    return qualities;
  }
}

class Quality {
  final Uri url;
  final int priority;
  final String name;

  Quality({required this.url, required this.priority, required this.name});
}
