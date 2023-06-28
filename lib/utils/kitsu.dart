import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KitsuApi {
  // All copied from tachiyomi
  static const clientId =
      "dd031b32d2f56c990b1425efe6c42ad847e7fe3ab46bf1299f05ecd856bdb7dd";
  static const clientSecret =
      "54d7307928f63414defd96399fc31ba847961ceaecef3a5fd93144e960c0e151";
  static const baseUrl = "https://kitsu.io/api/edge/";
  static const loginUrl = "https://kitsu.io/api/oauth/token";
  static const baseMangaUrl = "https://kitsu.io/manga/";
  static const algoliaKeyUrl = "https://kitsu.io/api/edge/algolia-keys/media/";
  static const algoliaUrl =
      "https://AWQO5J657S-dsn.algolia.net/1/indexes/production_media/query/";
  static const algoliaAppId = "AWQO5J657S";
  static const algoliaFilter =
      "&facetFilters=%5B%22kind%3Amanga%22%5D&attributesToRetrieve=%5B%22synopsis%22%2C%22canonicalTitle%22%2C%22chapterCount%22%2C%22posterImage%22%2C%22startDate%22%2C%22subtype%22%2C%22endDate%22%2C%20%22id%22%5D";

  static Future<void> login(String username, String password) async {
    final res = await http.post(
      Uri.parse(loginUrl),
      body: {
        "username": username,
        "password": Uri.encodeFull(password),
        "grant_type": "password",
        "client_id": clientId,
        "client_secret": clientSecret,
      },
    );
    final grant = jsonDecode(res.body);

    if (grant["error"] != null) {
      throw Exception(grant["error"]);
    }
    KitsuCreds.saveCreds(
      KitsuCreds(
        accessToken: grant["access_token"],
        expiresIn: grant["expires_in"],
        refreshToken: grant["refresh_token"],
      ),
    );
  }

  static Future<String> getUserId(String username) async {
    final res = await http.get(
        Uri.parse("https://kitsu.io/api/edge/users?filter[name]=$username"));
    return jsonDecode(res.body)["data"][0]["id"];
  }

  static Future getUserLibrary(
    String userId, {
    int? limit = 10,
    int? offset = 0,
    Map<String, String>? filters,
    String? sort = "status,-progressed_at,-updated_at",
  }) async {
    final filterQuery = (filters ?? {})
        .entries
        .map((e) => "&filter[${e.key}]=${e.value}")
        .join("");
    final res = await http.get(Uri.parse(
      "https://kitsu.io/api/edge/users/$userId/library-entries"
      "?page[limit]=$limit&page[offset]=$offset$filterQuery"
      "&sort=$sort",
    ));
    return jsonDecode(res.body);
  }

  static Future getLibEntryAnimeDetails(String entryId) async {
    final res = await http.get(
        Uri.parse("https://kitsu.io/api/edge/library-entries/$entryId/anime"));
    return jsonDecode(res.body);
  }
}

class KitsuCreds {
  static void saveCreds(KitsuCreds kitsuCreds) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("kitsu-AccessToken", kitsuCreds.accessToken);
    prefs.setInt("kitsu-ExpiresIn", kitsuCreds.expiresIn);
    prefs.setString("kitsu-RefreshToken", kitsuCreds.refreshToken);
  }

  static Future<KitsuCreds> fromSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString("kitsu-AccessToken") == null) {
      throw Exception("No Access Token");
    }
    return KitsuCreds(
      accessToken: prefs.getString("kitsu-AccessToken")!,
      expiresIn: prefs.getInt("kitsu-ExpiresIn")!,
      refreshToken: prefs.getString("kitsu-RefreshToken")!,
    );
  }

  final String accessToken;
  final int expiresIn;
  final String refreshToken;
  KitsuCreds({
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });
}
