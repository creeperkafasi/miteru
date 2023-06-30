import 'dart:convert';

import 'package:http/http.dart' as http;

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
          segment ^= password.codeUnitAt(i);
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
}
