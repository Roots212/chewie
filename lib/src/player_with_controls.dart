import 'package:chewie/src/chewie_player.dart';
import 'package:chewie/src/helpers/adaptive_controls.dart';
import 'package:chewie/src/multihit_stack.dart';
import 'package:chewie/src/notifiers/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  const PlayerWithControls(
      {Key? key,
      required this.canCompare,
      required this.canZoom,
      required this.compareWidget})
      : super(key: key);
  final bool canCompare;
  final ValueNotifier<bool> canZoom;
  final Widget compareWidget;

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);
    final ValueNotifier<bool> isInitialised = ValueNotifier(false);
    chewieController.videoPlayerController.addListener(() {
      if (chewieController.videoPlayerController.value.isInitialized) {
        isInitialised.value = true;
      }
    });
    double calculateAspectRatio(BuildContext context) {
      final size = MediaQuery.of(context).size;
      final width = size.width;
      final height = size.height;

      return width > height ? width / height : height / width;
    }

    Widget buildControls(
      BuildContext context,
      ChewieController chewieController,
    ) {
      return chewieController.showControls
          ? chewieController.customControls ?? const AdaptiveControls()
          : const SizedBox();
    }

    Widget buildPlayerWithControls(ChewieController chewieController,
        bool canCompare, BuildContext context) {
      return MultiHitStack(
        children: <Widget>[
          if (chewieController.placeholder != null)
            chewieController.placeholder!,
          Column(
            children: [
              if (canCompare) compareWidget,
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: canCompare
                    ? MediaQuery.of(context).size.height / 2
                    : MediaQuery.of(context).size.height,
                child: ValueListenableBuilder(
                    valueListenable: canZoom,
                    builder: (context, value, child) {
                      return IgnorePointer(
                        ignoring: !value,
                        child: InteractiveViewer(
                          transformationController:
                              chewieController.transformationController,
                          maxScale: chewieController.maxScale,
                          panEnabled: chewieController.zoomAndPan,
                          scaleEnabled: chewieController.zoomAndPan,
                          child: FittedBox(
                              fit: BoxFit.cover,
                              clipBehavior: Clip.antiAlias,
                              child: ValueListenableBuilder<bool>(
                                valueListenable: isInitialised,
                                builder: (context, value, child) {
                                  if (value) {
                                    return SizedBox(
                                        height: canCompare
                                            ? chewieController
                                                    .videoPlayerController
                                                    .value
                                                    .size
                                                    .height /
                                                2
                                            : chewieController
                                                .videoPlayerController
                                                .value
                                                .size
                                                .height,
                                        width: chewieController
                                            .videoPlayerController
                                            .value
                                            .size
                                            .width,
                                        child: VideoPlayer(chewieController
                                            .videoPlayerController));
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              )),
                        ),
                      );
                    }),
              ),
            ],
          ),
          if (chewieController.overlay != null) chewieController.overlay!,
          if (Theme.of(context).platform != TargetPlatform.iOS)
            Consumer<PlayerNotifier>(
              builder: (
                BuildContext context,
                PlayerNotifier notifier,
                Widget? widget,
              ) =>
                  Visibility(
                visible: !notifier.hideStuff,
                child: AnimatedOpacity(
                  opacity: notifier.hideStuff ? 0.0 : 0.8,
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
          if (chewieController.topControls == null)
            if (!chewieController.isFullScreen)
              buildControls(context, chewieController)
            else
              SafeArea(
                bottom: false,
                child: buildControls(context, chewieController),
              ),
          if (chewieController.topControls != null)
            SizedBox(
                height: chewieController.topBarHeight,
                width: MediaQuery.of(context).size.width,
                child: chewieController.topControls!),
          if (chewieController.bottomControls != null)
            Positioned(
              bottom: 5,
              child: SizedBox(
                  height: chewieController.bottomHeight,
                  width: MediaQuery.of(context).size.width,
                  child: chewieController.bottomControls!),
            ),
        ],
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: AspectRatio(
        aspectRatio: calculateAspectRatio(context),
        child: buildPlayerWithControls(chewieController, canCompare, context),
      ),
    );
  }
}
