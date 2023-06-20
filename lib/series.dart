import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';

class SeriesOverview extends StatefulWidget {
  const SeriesOverview({super.key});

  @override
  State<SeriesOverview> createState() => _SeriesOverviewState();
}

class _SeriesOverviewState extends State<SeriesOverview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}