import 'package:flutter/material.dart';
import 'package:miteru/utils/kitsu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String email = "";
  String password = "";
  String username = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log into Kitsu")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: "Username"),
                  onChanged: (value) => username = value,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setString(
                        "kitsu-User",
                        await KitsuApi.getUserId(username),
                      );
                    },
                    child: const Text("Set User"),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: "Email"),
                  onChanged: (value) => email = value,
                ),
                TextField(
                  decoration: const InputDecoration(hintText: "Password"),
                  onChanged: (value) => password = value,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () => KitsuApi.login(email, password).then(
                      (value) => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Successfuly logged in"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Ok"),
                            )
                          ],
                        ),
                      ),
                      onError: (error, stackTrace) => showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Error"),
                          content: Text(error.toString()),
                        ),
                      ),
                    ),
                    child: const Text("Authorize"),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Container()),
          TextButton.icon(
            onPressed: () =>
                SharedPreferences.getInstance().then((value) => value.clear()),
            icon: const Icon(Icons.delete),
            label: const Text("Clear Shared Preferences"),
          )
        ],
      ),
    );
  }
}
