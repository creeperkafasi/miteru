import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:text_scroll/text_scroll.dart';

class WatchPage extends StatefulWidget {
  final dynamic source;
  final dynamic showData;
  const WatchPage({super.key, required this.source, required this.showData});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text("Watch ${widget.showData["name"]}"),
      ),
    );
  }
}
