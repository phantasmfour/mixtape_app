import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mini_player.dart';
import 'now_playing_screen.dart';
import 'playlist_detail_screen.dart';
import 'playlist_manager.dart';

/*
Used to show the playlists a user has. Kind of boring looking
 */
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({Key? key}) : super(key: key);

  @override
  _PlaylistsScreenState createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  late Stream<QuerySnapshot> playlistsStream; // Keep track of the playlists being deleted or added
  late PlaylistManager playlistManager;

  @override
void initState() {
  super.initState();
  playlistManager = PlaylistManager(); // init playlist manager
  playlistsStream = playlistManager.getPlaylistsStream();
}

  Future<void> _removePlaylist(playlistId) async {  // Can be all in the single line but looks a bit better out here.
    await playlistManager.deletePlaylist(playlistId);
    setState(() {}); // Refresh the UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playlist removed')),
    );
  }

  Future<void> _confirmDelete(playlist) async {  // Confirm if a user actually wants to delete a playlist
    final String? playlistName = playlist['name'];  // used to show the name of the playlist
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Song'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to remove the playlist named $playlistName?'),
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
                _removePlaylist(playlist.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[900],
    appBar: AppBar(
      title: const Text(
        'Playlists', // Don't feel a need to search playlists.
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: Colors.grey[900],
      iconTheme: IconThemeData(color: Colors.white),
    ),
    body: Container(

  child: Column(
  children: [
    Expanded(
  child: StreamBuilder<QuerySnapshot>(  // Changed the type here to QuerySnapshot
      stream: playlistsStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading playlists'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {  // Updated this line to check if docs is empty
          return const Center(child: Text('No playlists found'));
        } else {
          return ListView.builder(  // Build playlist list
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var playlist = snapshot.data!.docs[index];
              return Card(  // No images so simple cards/
                color: Colors.grey[850],
                child: ListTile(
                  leading: const Icon(Icons.scatter_plot_rounded), // Just a fun icon
                  title: Text(
                    playlist['name'],
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () { // Send to playlist detail
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(playlistSongs: playlist['songs'],playlistId: playlist.id,playlistName: playlist['name']),
                      ),
                    );
                  },
                  onLongPress: (){_confirmDelete(playlist);}  // Delete song
                ),
              );
            },
          );

        }
      },
    )),MiniPlayer( // Mini player
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NowPlayingScreen(),
        ),
      );
    },
  )])),floatingActionButton: FloatingActionButton(  // Can make playlist from playlist screen.
    backgroundColor: Colors.black,
    child: Icon(Icons.add,color: Colors.grey,),
      onPressed: () async {
        var playlistName;
        // You can use a dialog or another screen to get the playlist name from the user
        playlistName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('New Playlist'),
              content: TextField(
                decoration: InputDecoration(hintText: "Enter playlist name"),
                onChanged: (value) {
                  playlistName = value;
                },
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, playlistName);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        if (playlistName != null && playlistName?.isNotEmpty) {
          await playlistManager.createPlaylist(playlistName);
        }
      },
  ),
  );
}
}