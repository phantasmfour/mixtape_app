import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_service/audio_service.dart';


/*
This made life easier and harder. There is a real package which I import above Audio_Service
I think GPT got confused when suggesting this name.
This stopped me from doing a few cool things like multiple Audio Players with background audio
If I were to redo this I would have not used this name and used the actual audio_service.

This class is the backbone to the entire thing since it handles the music playing functions. Since I need it in multiple places it made sense to put it in a class.
 */

class AudioService extends ChangeNotifier{

  int currentIndex = -1; // This should cause an error so if we did not get an index we should crash.
  String? imageURL;

  List<dynamic> songs = [];
  AudioPlayer activePlayer = AudioPlayer(); // We used to have 3 players. One current player. the second would get preloaded with the next song
  // The third player was active player. But just_audio_background only supports one player and audio_service would have been hard to implement
  // We lose the preloading but with allowing users to download songs we should be fine. HLS is also used now so that should help with loads.
  // More time and patience I would have rewritten.

  Map<String, dynamic>? currentSong = {"title":"Unknown Song","artist":"Unknown Artist"}; // Default data for now playing screen to show.

  Future<File?> _getLocalFile(String fileName) async {  // To check if the song has been locally downloaded.
    var dir = await getApplicationDocumentsDirectory();
    var path = '${dir.path}/$fileName.mp3';
    return File(path);
  }

  void initAudio(){ // If this is not run then the mini_player and now_playing_screen won't update. This gets run from the queue set since I could not run it on init.
  activePlayer.currentIndexStream.listen((state) {  // Must listen for when the index of the queue is updated by Just Audio.
    // this updates the song info and notifies the UI to update
      if (activePlayer.currentIndex != null && activePlayer.currentIndex != currentIndex){  // Current index has changed? That means there is a new song
        currentIndex = activePlayer.currentIndex!;
        currentSong = songs[currentIndex];
        notifyListeners(); // Notify provider watchers.
      }
  });
}
  String getAudioUrlForCurrentPlatform(song) {
    if (kIsWeb) {
      return song['mp3Url'];  // Serve MP3 for web
    } else {
      return song['m3u8Url']; // Serve HLS (m3u8) for mobile platforms
    }
  }

  play() {
    activePlayer.play;
  }
  pause(){
    activePlayer.pause;
  }
  void dispose() {
  activePlayer.dispose();
  }



  setNewQueue(songQueue,index,song,songsPass,coverURL) async { // Song_lists_screen and playlist_Detail_screen call this to set the queue of songs
    // Don't just play the single song setup the next ones to be played
    imageURL = coverURL;
    songs = songsPass;
    currentSong = songs[index];
    currentIndex = index;
    List<AudioSource> realQueue = [];

    for (var song in songQueue) { // Loop checking if the songs have been downloaded locally rather then streaming them.
      if (kIsWeb) {
          // Online URL if you are on the web
          realQueue.add(
              AudioSource.uri(Uri.parse(getAudioUrlForCurrentPlatform(song)),
                // Use MP3 or M3U8 depending on the playform
                tag: MediaItem( // Notification  + Lock screen needs meta data to know song you are playing.
                  // Specify a unique ID for each media item:
                  id: '1',
                  // Metadata to display in the notification:
                  artist: song['artist'],
                  title: song['title'],
                  artUri: Uri.parse(song['coverUrl']),
                ),));
      }
      else {
          var localFile = await _getLocalFile(song['title']);

          if (localFile != null && await localFile.exists()) {
            // Use local file if it exists
            realQueue.add(AudioSource.uri(Uri.file(localFile.path),
              tag: MediaItem( // Notification  + Lock screen needs meta data to know song you are playing.
                // Specify a unique ID for each media item:
                id: '1',
                // Metadata to display in the notification:
                artist: song['artist'],
                title: song['title'],
                artUri: Uri.parse(song['coverUrl']),
              ),));
          } else {
            // Otherwise use online URL
            realQueue.add(
                AudioSource.uri(Uri.parse(getAudioUrlForCurrentPlatform(song)),
                  // Use MP3 or M3U8 depending on the playform
                  tag: MediaItem( // Notification  + Lock screen needs meta data to know song you are playing.
                    // Specify a unique ID for each media item:
                    id: '1',
                    // Metadata to display in the notification:
                    artist: song['artist'],
                    title: song['title'],
                    artUri: Uri.parse(song['coverUrl']),
                  ),));
          }
        }
    }
    final playlist = ConcatenatingAudioSource(useLazyPreparation: true, children: realQueue);  // Create the playlist from the queue
    await activePlayer.setAudioSource(playlist, initialIndex: index, initialPosition: Duration.zero);  // Use the playlist. use the await to make sure the song loads first
    activePlayer.play();  // Play the audio source and initial index song that the user selected

    initAudio();  // watch the active player current index for updates so we can notify other pages.
  }

  void goToNext(){  // Need to update the index so other pages know.
    activePlayer.seekToNext();
    currentIndex++;
    currentSong = songs[currentIndex];
    notifyListeners();
  }
  void goToPrevious(){ // Need to update the index so other pages know.
    if (activePlayer.position.inSeconds > 3) {  // Restart song or go to previous?
      activePlayer.seek(Duration.zero);
    } else {
      activePlayer.seekToPrevious();
      currentIndex--;
      currentSong = songs[currentIndex];
      notifyListeners();
    }
  }

  Future<File?>? downloadFile(String url, String fileName) async {  // Used to download songs
    var status = await Permission.storage.status;
    if (!status.isGranted) {  // Be nice and ask the user
      await Permission.storage.request();
    }

    var dir = await getApplicationDocumentsDirectory();
    var path = '${dir.path}/$fileName.mp3';  // Added .mp3 extension, adjust as needed
    var file = File(path);

    if (await file.exists()) {
      return null;  // Return null or the file if you wish
    } else {
      var dio = Dio();
      await dio.download(url, path);  // DIO used to download the files
      return file;
    }
  }

  }


/* Legacy preloading code
  Future<void> _preloadNextSong() async {
    AudioPlayer playerToPreload = isCurrentPlayerActive
        ? nextPlayer
        : currentPlayer; // Use the non active player
    //print(playerToPreload);
    var localFile = await _getLocalFile(songs[currentIndex + 1]['title']);

    if (localFile != null && await localFile.exists()) {
      // Use local file if it exists
      playerToPreload.setAudioSource(AudioSource.uri(Uri.file(localFile.path)));
    } else {
      playerToPreload.setUrl(getAudioUrlForCurrentPlatform(
          songs[currentIndex + 1])); // Preload the next song
      //playerToPreload.pause();  // Needed or this song will start instantly on the load.
      //print("PRELOADING");
      //print(isCurrentPlayerActive);

    }
  }

   */

/*
      if (index < songs.length - 1) {
        if (isCurrentPlayerActive) {
          var localFile = await _getLocalFile(songs[currentIndex + 1]['title']);

          if (localFile != null && await localFile.exists()) {
            // Use local file if it exists
            nextPlayer.setAudioSource(
                AudioSource.uri(Uri.file(localFile.path)));
          } else {
            nextPlayer.setUrl(getAudioUrlForCurrentPlatform(songs[index + 1]));
            // Preload next song async so we just keep running so no await keyword
          }
        }
        else {
          var localFile = await _getLocalFile(songs[currentIndex + 1]['title']);

          if (localFile != null && await localFile.exists()) {
            // Use local file if it exists
            currentPlayer.setAudioSource(
                AudioSource.uri(Uri.file(localFile.path)));
          } else {
            currentPlayer.setUrl(
                getAudioUrlForCurrentPlatform(songs[index + 1]));
          }
        }
      }

     */