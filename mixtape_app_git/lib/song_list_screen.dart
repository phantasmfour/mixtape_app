import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';  // Needed to check if the user is using a browser or on mobile
import 'package:provider/provider.dart';
import 'audio_service.dart';
import 'download_button.dart';
import 'now_playing_screen.dart';
import 'playlist_manager.dart';
import 'mini_player.dart';

/*
Used to show the list of songs in an album and also give users the ability to download them or add them to a playlist.
 */
class SongListScreen extends StatefulWidget {
  final String albumName;
  final String artist;
  final String coverUrl;
  final List<dynamic> songs;
  // These come in from album_list_screen

  SongListScreen({
    required this.albumName,
    required this.artist,
    required this.coverUrl,
    required this.songs,
  });

  @override
  _SongListScreenState createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
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
    final audioService = context.watch<AudioService>();

    return Scaffold(

      body: Container(
        color: Colors.grey[900],
      child: LayoutBuilder(
        builder: (context, constraints) {
      double imageSize = constraints.maxWidth / 2 - 120;  // Getting a little fancy and might not work everywhere for dynamic scaling
      return Stack(
        // This is so complicated with the slivers since I wanted the app bar to disappear on scroll
        // To do this we needed the custom scroll view
        children: [CustomScrollView(
        slivers: [
          SliverAppBar(  // Able to have a back button and album data in a bar that disappears
            backgroundColor: Color(0xFF333333),
            expandedHeight: 120.0,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.network(
                        widget.coverUrl,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: imageSize,
                            width: imageSize,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.cloud_off, color: Colors
                                  .white), // optional: add an error icon or message
                            ),
                          );
                        }
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.albumName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                          ),
                        ),
                        Text(
                          widget.artist,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                    Spacer()
                  ],
                ),
              ),
            ),
          ),
          SliverList(  // Song list

            delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                var song = widget.songs[index];  // I am using the widget Vars everywhere. I don't know if its bad to do so. Easier then wasting memory on local variables so I will assume its better
                return Column(
                  children: [
                    ListTile(
                      leading: DownloadButton(url: song['mp3Url'], title: song['title']),  // Have a download button on the left
                      title: Text(song['title'], style: TextStyle(color: Colors.white)),
                      subtitle: Text(widget.artist, style: TextStyle(color: Colors.white70)),
                    onTap: () async {  // Doing a build over async I know. But setting the queue of songs in the album and then playing them.
                        await audioService.setNewQueue(widget.songs, index, widget.songs[index],widget.songs, widget.coverUrl);
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => NowPlayingScreen(
                        ),
                        ),
                        );
                        },
                    trailing: IconButton(icon: Icon(Icons.playlist_add,color: Colors.white,), // Can add directly to the playlist
                      onPressed: () { _addToPlaylist(song); },
                    ),
                    ),
                    Divider(color: Colors.grey[800], height: 0.5) // Styling
                  ],
                );
              },
              childCount: widget.songs.length,
            ),
          ),
          // Adding a SliverPadding to the bottom to avoid the miniplayer overlay
          SliverPadding(
            padding: EdgeInsets.only(bottom: 75), // Adjust the padding as needed
          )// Used because the mini player will sometimes cover the last song. Not a big deal to have the padding and its an easy win
        ],
      ),
    Positioned( // Since the Sliver is not really there as a widget this will just go to the top. You need to force it to the bottom
    left: 0,
    right: 0,
    bottom: 0,
    child: MiniPlayer(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NowPlayingScreen(
                      ),
                ),
              );
            },
          ))
    ]
    );})));

    }



  void _addToPlaylist(Map<String, dynamic> song) async {
    // This is a little more complicated since the user needs to choose the playlist
    // Its hard to do this all from playlist manager since I am unsure if we can show things from a module.
    // We only use it here so not looking into it too much to see if its possible/better in the manager.
    final manager = PlaylistManager();
    final playlists = await manager.getPlaylists();

    if (playlists.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No playlists available')),
      );
      return;
    }

    final selectedPlaylist = await showModalBottomSheet<QueryDocumentSnapshot>(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: playlists.docs.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(playlists.docs[index]['name']),
              onTap: () => Navigator.of(context).pop(playlists.docs[index]),
            );
          },
        );
      },
    );

    if (selectedPlaylist != null) {
      await manager.addSongToPlaylist(selectedPlaylist.id, song);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added to ${selectedPlaylist['name']}')), // These are just the easiest error messages
      );
    }
  }

}
