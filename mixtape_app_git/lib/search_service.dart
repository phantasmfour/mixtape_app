import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'song_list_screen.dart';

/*
Used to make a semi working search bar that I only use on the album list screen.
Could have its own tab but wanted to keep things simple

Firestore does not like fuzzy match, you need an exact match.
I implemented keywords to help but I needed a different DB for this if wanted
easier queries.

I am just really using it to search for a song within an album.
Basically is hte song I am looking for on the app?
 */
class SearchService {
  searchByName(String searchField) {  // The bread and butter class searching the keywords
    return FirebaseFirestore.instance
        .collection('albums')
        .where('keywords',
        arrayContains: searchField.toLowerCase())
        .get();
  }
}


class DataSearch extends SearchDelegate<String> {

  @override
  ThemeData appBarTheme(BuildContext context) {  // The search lives in the app bar
    return Theme.of(context).copyWith(
      primaryColor: Colors.grey[900], // Had a very hard time formating the colors to make this look seemless on album list screen.
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: Colors.grey[900], // Add this
        secondary: Colors.grey[900], // And this
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 18.0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(  // For inputs
        filled: true,
        fillColor: Colors.grey[900],
        hintStyle: TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white70),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Colors.white70, // you can change this color
        selectionHandleColor: Colors.white70, // and this color
      ),
    );
  }
  @override
  List<Widget> buildActions(BuildContext context) {  // used within the app bar
    // These are not explicity called anywhere but they do somehow get taken into account by the app bar
    return [
      Container(
        color: Colors.grey[900],
        child: IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
      )
    ];

  }

  @override
  Widget buildLeading(BuildContext context) {  // used within the app bar.
    return Container(
      color: Colors.grey[900],
        child: IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, '');
      },
    ));
  }

  @override
  Widget buildResults(BuildContext context) {  // Duping buildSuggestions
    // This function is used when soome hits enter
    if (query.isEmpty) {
      return Container(
          color: Colors.grey[900],
          child: Center(child: Text('Start typing to search',style: TextStyle(color: Colors.white70))));
    }
    SearchService searchService = SearchService();  // Search


    return FutureBuilder<QuerySnapshot>(
      future: searchService.searchByName(query),  // Search query
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: Colors.white,),
          );
        }

        final results = snapshot.data!.docs;
        return Container(
          color: Colors.grey[900],
          child: ListView.builder(  // Show list of results
            itemCount: results.length,
            itemBuilder: (context, index) {
              var data = results[index].data() as Map<String, dynamic>;
              return Card(  // I like showing the image and the text.
                color: Color(0xFF333333),
                child: ListTile(
                  leading: Image.network(data['coverUrl'], fit: BoxFit.cover),
                  title: Text(
                      data['album'], style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      data['artist'], style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SongListScreen(
                              albumName: data['album'],
                              artist: data['artist'],
                              coverUrl: data['coverUrl'],
                              songs: data['songs'],
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

  }

  @override
  Widget buildSuggestions(BuildContext context) {  // Used for suggesting results while someone is still typing
    // I am using it to just display results regardless. Every keystroke is a submit
    if (query.isEmpty) {
      return Container(
        color: Colors.grey[900],
          child: Center(child: Text('Start typing to search',style: TextStyle(color: Colors.white70))));
    }
    SearchService searchService = SearchService();


    return FutureBuilder<QuerySnapshot>(
      future: searchService.searchByName(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: Colors.white,),
          );
        }

        final results = snapshot.data!.docs;
        return Container(
          color: Colors.grey[900],
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              var data = results[index].data() as Map<String, dynamic>;
              return Card(
                color: Color(0xFF333333),
                child: ListTile(
                  leading: Image.network(data['coverUrl'], fit: BoxFit.cover),
                  title: Text(
                      data['album'], style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      data['artist'], style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SongListScreen(
                              albumName: data['album'],
                              artist: data['artist'],
                              coverUrl: data['coverUrl'],
                              songs: data['songs'],
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}