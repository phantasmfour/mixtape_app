import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:new_mix/download_button.dart';
import 'package:provider/provider.dart';
import 'mini_player.dart';
import 'now_playing_screen.dart';
import 'playlist_manager.dart';
import 'audio_service.dart';

/*
No longer passing the playlist ID here just to load the data again. its all on
the screen so just send it over
The ID is passed to the playlist manager when you want to delete things

This handles showing the songs in the playlist, letting you play them and
deleting them.

 */

class PlaylistDetailScreen extends StatefulWidget {
  final List<dynamic> playlistSongs;
  final String playlistId;
  final String playlistName;

  const PlaylistDetailScreen({Key? key, required this.playlistSongs, required
  this.playlistId, required this.playlistName}) : super(key: key);

  @override
  _PlaylistDetailScreenState createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late List<Map<String, dynamic>> _songs;
  final PlaylistManager playlistManager = PlaylistManager();
  late List<dynamic> songList;

  Future<void> _removeSong(Map<String, dynamic> song) async {  // remove song from playlist
    // Done here to refresh UI without having a listener to the firebase doc.
    // Saves some bandwidth.
    await playlistManager.removeSongFromPlaylist(widget.playlistId, song);
    widget.playlistSongs.remove(song);
    setState(() {}); // Refresh the UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Song removed from playlist')),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> song) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Song'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Are you sure you want to remove this song from the playlist?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                _removeSong(song);  // calls the function above.
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Used to check if user is on browser or other platform(browser no hls support)
  String getAudioUrlForCurrentPlatform(song) {
    if (kIsWeb) {
      return song['mp3Url'];  // Serve MP3 for web
    } else {
      return song['m3u8Url']; // Serve HLS (m3u8) for mobile platforms
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService= context.watch<AudioService>();  // Watching service for updates
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Text(
          widget.playlistName,  // Make it look better
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container( // Need the container or else the view of the column has unlimited height
    child:
    Column(

    children: [
      Expanded( // Also need the expanded or height errors
        child:
      widget.playlistSongs.isEmpty
          ? Center(child: Text('No songs in this playlist', style: TextStyle(color: Colors.white)))
          : ListView.builder(
        itemCount: widget.playlistSongs.length,
        itemBuilder: (context, index) {
          var song = widget.playlistSongs[index];
          return Card(
            color: Colors.grey[850],
            child: ListTile(
              leading: DownloadButton(url: song['mp3Url'], title: song['title']),  // Showing a download button from within the playlist as until you get into making the queue this is fine to download
              title: Text(song['title'],style: TextStyle(color: Colors.white)),
              subtitle: Text(song['artist'], style: TextStyle(color: Colors.white70)),
              onTap: () async {
                await audioService.setNewQueue(widget.playlistSongs, index, widget.playlistSongs[index],widget.playlistSongs, widget.playlistSongs[index]['coverUrl']);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NowPlayingScreen(
                    ),
                  ),
                );
              },
              onLongPress: () {  // Long press deletes songs from playlist
                _confirmDelete(song);
              },
            ),
          );
        },
      )),
      MiniPlayer(  // Standard mini player.
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => NowPlayingScreen(),
            ),
          );
        },
      ),
    ]
    ))

    );
  }
}


