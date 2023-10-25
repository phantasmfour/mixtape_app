import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'now_playing_screen.dart';
import 'song_list_screen.dart';
import 'playlist_manager.dart';
import 'mini_player.dart';
import 'search_service.dart';

class AlbumListScreen extends StatefulWidget {
  @override
  _AlbumListScreenState createState() => _AlbumListScreenState();
}
class _AlbumListScreenState extends State<AlbumListScreen> {
  final playlistManager = PlaylistManager();

  List<QueryDocumentSnapshot<Object?>> albums = [];
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(  //Dont really need a title figured search bar is good.
        backgroundColor: Colors.black87,
        leading:
          IconButton( // Search bar calls the more complicated search delegate
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: DataSearch());
            },
          ),
        actions: <Widget>[  // Signout button
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          )
        ],
      ),
    body: Container(
    color: Colors.grey[900],
    child: Column(
      children: [
  Expanded(
    child: StreamBuilder<QuerySnapshot>( // Pulls the albums
    stream: FirebaseFirestore.instance.collection('albums').snapshots(),
    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (!snapshot.hasData || snapshot.data!.docs.length < 1) {
        return Center(child: CircularProgressIndicator(color: Colors.white,));
      }// Loading if no data
      else {

        return LayoutBuilder(
        builder: (context, constraints) {
          double width = constraints.maxWidth;
          double aspectRatio = width < 600 ? 9 / 18 : 9 / 10; // very hacky way to adjust the aspect ratio dont like it but its good.
          return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            // Can change the cross Axis Count. Kind of into the movie poster look for now
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: aspectRatio
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var album = snapshot.data!.docs[index].data() as Map<String,dynamic>;  // All albums from firestore.
            return GestureDetector(  // If pressed on the album send this data to the song list screen.
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      SongListScreen(
                        albumName: album["album"],
                        artist: album["artist"],
                        coverUrl: album["coverUrl"],
                        songs: album['songs'],
                      ),
                ));
              },
              child: Card(  // Cards that you see on the streen.
                color: Color(0x96696868),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                margin: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                        child: Image.network(
                          album['coverUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.black,
                              child: Center(
                                child: Icon(Icons.cloud_off, color: Colors.white),  // optional: add an error icon or message
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        album['album'],
                        style: TextStyle( fontSize: kIsWeb && MediaQuery.of(context).size.width > 800
                            ? 20  // Font size for web
                            : 14, // Font size for mobile, Probably not the best solution
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        album['artist'],
                        style: TextStyle(fontSize: kIsWeb && MediaQuery.of(context).size.width > 800
                            ? 20  // Font size for web
                            : 14, // Font size for mobile,
                            color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },);});
      }
    })),
        MiniPlayer(  // Add the mini player
        onTap: () {
          Navigator.of(context).push(
          MaterialPageRoute(
          builder: (context) => NowPlayingScreen(),
          ),
            );
            },
              ),
      ],
    ),
    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.add,color: Colors.grey,),
        onPressed: () async {
          var playlistName;
          playlistName = await showDialog<String>(  // The dialogs are just really easy to use
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
            await playlistManager.createPlaylist(playlistName);  // Have the playlist manager take care of all that code as we use this in many places
          }
        },
      ),
    );
  }
  }


// Could have implemented queue
// Downloading images when offline.
// Deleting downloaded songs

// One thing I don't fully understand is Firestore seems to natively just handle the caching. Docs seem to still have all data when offline. Must be abstracted away.

