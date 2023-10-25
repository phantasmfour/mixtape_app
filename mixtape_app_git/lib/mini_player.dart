import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:new_mix/audio_service.dart';
import 'package:provider/provider.dart';
import 'now_playing_screen.dart';

/*
Used to show a mini player at the bottom of the screen as a widget.
 */
class MiniPlayer extends StatelessWidget {
  final Function onTap;

  MiniPlayer({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioService= context.watch<AudioService>();  // Provider listens for state changes to the audioService class

    return GestureDetector(  // Wrap entire MiniPlayer widget so if any of it is clicked it does the navigation
        onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NowPlayingScreen(),
        ),
      );
    },
    child: StreamBuilder<PlayerState>(
      stream: audioService.activePlayer.playerStateStream,  // Listen to player stream
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        if (audioService.currentSong?["title"]=="Unknown Song") {  // Default
          return SizedBox.shrink();
        }
        return Container(
        color: Color(0xFF3601AD),  // I like this purple
          child: Container(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(  // Tracking the player state to see if paused or playing
                    playerState?.playing == true
                        ? Icons.pause
                        : Icons.play_arrow,
                      color: Colors.white
                  ),
                  iconSize: 38.0,
                  onPressed: () {
                    if (playerState?.playing == true) {
                      audioService.activePlayer.pause();
                    } else {
                      audioService.activePlayer.play();
                    }
                  },
                ),
                Text(
                audioService.currentSong?['title'],
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18.0)
                ),
              ],
            ),
          ),
        );
      },
    ));
  }
}