import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'audio_service.dart';
import 'package:flutter/foundation.dart';  // Needed to check if the user is using a browser or on mobile

/*
Regular now playing screen with minimal features to just show if we are playing something and to control it in more detail than miniplayer

Does not even take any arguments just pulls the data directly from the audio_service class.
This made it easier to have mini_player on multiple screens
 */
class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});


  // Used to check if user is on browser or other platform(browser no hls support)
  String getAudioUrlForCurrentPlatform(song) {
    if (kIsWeb) {
      return song['mp3Url']; // Serve MP3 for web
    } else {
      return song['m3u8Url']; // Serve HLS (m3u8) for mobile platforms
    }
  }


  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();  // Listen for updates to the audio service
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Color(0xFF333333),
        title: Text('Now Playing', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
          child: Center(
          child: Container(  // Makes all images look a little standard. Plus deviates from the album_list_screen where we go 9/16 for the images
            width: 200.0,
            height: 200.0,
            decoration: BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.cover,
                image: NetworkImage(audioService.currentSong?['coverUrl']),
              ),
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(  // Looks nice around the image
                  color: Colors.black45,
                  offset: Offset(0, 4),
                  blurRadius: 6.0,
                ),
              ],
            ),
          ),
        ),
        ),
          Padding(  // Making the data about the song look nice.
          padding: const EdgeInsets.all(16.0),
          child: Column(
          children: [
          Text(
            audioService.currentSong?['title'],  // THis data should always be there.
          style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.bold,
          ),
          ),
          SizedBox(height: 8.0),
          Text(
            audioService.currentSong?['artist'],
          style: TextStyle(
          color: Colors.white70,
          fontSize: 18.0,
          ),
          ),
          SizedBox(height: 24.0),
            StreamBuilder<Duration>(  // This is the audio slider setup here
              stream: audioService.activePlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = audioService.activePlayer.duration ??
                    Duration.zero;
                if (duration.inMilliseconds == 0) { // there was an issue where we would create the slider before things loaded. This caused an issue that would try to make a seek bar that was 0 duration. with this you now see a quick load pop up. Could set this to one like final duration = widget.player.duration ?? Duration(seconds: 1); but don't think necessary
                  return CircularProgressIndicator(color: Colors.white,); // Display a loading indicator
                } else {
                  return Column(
                    children: [
                      Slider(
                        value: position.inMilliseconds.toDouble(),
                        onChanged: (value) {
                          audioService.activePlayer.seek(
                              Duration(milliseconds: value.round()));
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white38,
                        min: 0,
                        max: duration.inMilliseconds.toDouble(),
                      ),
                      Row( // For the song duration/ position text boxes
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Text(position
                              .toString()
                              .split('.')
                              .first,
                              style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18.0)),
                          Text(duration
                              .toString()
                              .split('.')
                              .first,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18.0)),
                        ],
                      ),
                    ],
                  );
                }
              },),
          SizedBox(height: 24.0),
            Row( // Pause skip and back icons
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                  icon: Icon(Icons.skip_previous, color: Colors.white),
                  iconSize: 32.0,
                  onPressed: () {
                    audioService.goToPrevious();  // Using audio service functions
                    },
                  ),
                  StreamBuilder<PlayerState>(  // Check if its playing to determine if we should show a pause or play icon. Or loading.
                    stream: audioService.activePlayer.playerStateStream,
                    builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 64.0,
                        height: 64.0,
                        child: const CircularProgressIndicator(color: Colors.white,),
                        );
                    }
                    else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      iconSize: 48.0,
                      onPressed: audioService.activePlayer.play,
                      );
                    }
                    else if (processingState != ProcessingState.completed) {
                      return IconButton(
                        icon: const Icon(Icons.pause, color: Colors.white),
                        iconSize: 48.0,
                        onPressed: audioService.activePlayer.pause,
                        );
                    }
                    else {
                    return IconButton(  // Not really used often. Might want to make this go back to the beginning of the playlist
                      icon: const Icon(Icons.replay, color: Colors.white),
                      iconSize: 48.0,
                      onPressed: () =>
                      audioService.activePlayer.seek(Duration.zero),
                      );
                    }
                    },
                    ),

                IconButton(
                icon: Icon(Icons.skip_next, color: Colors.white),
                iconSize: 32.0,
                onPressed: () {audioService.goToNext();},  // Using the audio Service to do this.
                ),
                ],
                ),
          ],
          ),
          )
            ],
          ),


    );
  }
}
