import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miteru/utils/allanime.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

class WatchPage extends StatefulWidget {
  final dynamic source;
  final List<Quality> qualities;
  final dynamic showData;
  const WatchPage(
      {super.key,
      required this.source,
      required this.showData,
      required this.qualities});

  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  int selectedQualityIndex = 0;

  VideoPlayerController? playerController;
  double aspectRatio = 16 / 9;

  Duration? savedPosition;

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
  }

  @override
  void dispose() {
    super.dispose();
    playerController?.dispose();
    Wakelock.disable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Shortcuts(
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.space): VoidCallbackIntent(
            () => playerController?.value.isPlaying ?? false
                ? playerController?.pause()
                : playerController?.play(),
          ),
          LogicalKeySet(LogicalKeyboardKey.arrowRight): VoidCallbackIntent(
            () async => playerController?.seekTo(
              (await playerController!.position)! + const Duration(seconds: 10),
            ),
          ),
          LogicalKeySet(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(
            () async => playerController?.seekTo(
              (await playerController!.position)! - const Duration(seconds: 10),
            ),
          ),
          LogicalKeySet(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(
            () async => playerController?.setVolume(
              (playerController!.value.volume + 0.1).clamp(0, 1),
            ),
          ),
          LogicalKeySet(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(
            () async => playerController?.setVolume(
              (playerController!.value.volume - 0.1).clamp(0, 1),
            ),
          ),
        },
        child: Focus(
          autofocus: true,
          child: SafeArea(
            child: Container(
              color: Colors.black,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Builder(builder: (context) {
                playerController = VideoPlayerController.networkUrl(
                  widget.qualities[selectedQualityIndex].url,
                );
                return Chewie(
                  controller: ChewieController(
                    startAt: savedPosition ?? Duration.zero,
                    autoPlay: savedPosition != null,
                    videoPlayerController: playerController!,
                    aspectRatio: aspectRatio,
                    autoInitialize: true,
                    additionalOptions: (context) => [
                      OptionItem(
                        onTap: () {
                          showDialog(
                              context: context,
                              builder: ((context) {
                                return SimpleDialog(
                                  title: const Text("Select Quality:"),
                                  children: [
                                    Column(
                                        children: widget.qualities
                                            .map(
                                              (e) => Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: TextButton.icon(
                                                  onPressed: () async {
                                                    savedPosition =
                                                        await playerController
                                                            ?.position;
                                                    setState(() {
                                                      playerController
                                                          ?.dispose();
                                                      selectedQualityIndex =
                                                          widget.qualities
                                                              .indexOf(e);
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.settings),
                                                  label: Text(e.name),
                                                ),
                                              ),
                                            )
                                            .toList()),
                                  ],
                                );
                              }));
                        },
                        iconData: Icons.high_quality,
                        title: "Quality",
                      )
                    ],
                    // autoPlay: true,
                    // fullScreenByDefault: true,
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
