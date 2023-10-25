import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
/*
Used to for most of the playlist functions
 */
class PlaylistManager {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> createPlaylist(String name) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('playlists').add({
      'name': name,
      'songs': [],
    });
  }
  Future<void> removeSongFromPlaylist(String playlistId, Map<String, dynamic> song) async {  // Used for when users hold down on a song.
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('playlists')
        .doc(playlistId)
        .update({
      'songs': FieldValue.arrayRemove([song]),
    });
  }


  Future<QuerySnapshot> getPlaylists() async {  // Returns the users playlists
    return await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('playlists').get();
  }

  Future<void> addSongToPlaylist(String playlistId, Map<String, dynamic> song) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('playlists')
        .doc(playlistId)
        .update({
      'songs': FieldValue.arrayUnion([song]),
    });
  }

  Future<List<dynamic>> getSongsInPlaylist(String playlistId) async {
    DocumentSnapshot playlist = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('playlists')
        .doc(playlistId)
        .get();
    return playlist['songs'] as List<dynamic>;
  }

  Future<void> deletePlaylist(String playlistId) async {  // Incase you no longer want it.
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('playlists')
        .doc(playlistId)
        .delete();
  }

  Stream<QuerySnapshot> getPlaylistsStream() {  // Used on the playlist screen to see if any playlists changed.
    return FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).collection('playlists').snapshots();
  }
}
