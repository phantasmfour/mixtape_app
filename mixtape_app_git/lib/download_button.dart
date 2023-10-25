import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/*
This is a fun one.
I had a lot of trouble getting the download button working inline
Since I am using both here and the playlist screen I am modularizing it

If the user already has the song downloaded show just an icon.
If not show a download button.
If download button clicked download the song and show a loading icon
Once downloaded show the same music icon like if you already downloaded it.

The futures are a little confusing and I don't know if I fully understand them even now.
 */

class DownloadButton extends StatefulWidget {
  final String url;
  final String title;

  const DownloadButton({Key? key, required this.url, required this.title}) : super(key: key);

  @override
  _DownloadButtonState createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  Future<File?>? _downloadFuture;

  @override
  void initState() {
    super.initState();
    _checkIfFileExists();  // So this needs to run on init to check if the file is local and kick off everything else.
    // We basically run this on every song. Its local to the OS so not a big deal not like querying the internet and downloading them all at once.
  }

  Future<void> _checkIfFileExists() async {
    final file = await _getLocalFile(widget.title);
    if (!file.existsSync()) {
      setState(() {
        _downloadFuture = null;  // This determines if we should show the download icon or the normal music icon. SO being null means does not exist
      });
    }
  }

  Future<File> _getLocalFile(String filename) async {  // Look through dirs
    var dir = await getApplicationDocumentsDirectory();
    var path = '${dir.path}/$filename.mp3';
    return File(path);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = context.watch<AudioService>();
    // The futures are a little confusing I think one is querying if the file exists locally
    // The next if then checking if you are downloading it and giving you the option to download it.

    if (kIsWeb) {
      // If running on web, return music note icon
      return const Icon(Icons.music_note);
    }
    return _downloadFuture == null
        ? FutureBuilder<File>(  // if null show the download since it does not exist
      future: _getLocalFile(widget.title),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.data!.existsSync()) {
          return Container(
              child: Center(child: Icon(Icons.music_note)), // This center did not work to center this for some reason. Need the height and width below. Might look worse on different os's
        height: 40, // Adjust the height as needed
        width: 41, // Adjust the width as needed // File already exists
          );
        } else {  // This else must somehow kick off the download future to start as without it everything is "downloaded"
          return IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              setState(() {
                _downloadFuture = audioService.downloadFile(
                    widget.url, widget.title);
              });
            },
          );
        }
      },
    )
        : FutureBuilder<File?>(  // File was not found locally Show the download options
      future: _downloadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasData || snapshot.data!.existsSync()) {
          return Container(
              height: 40, // Adjust the height as needed
              width: 41,
              child: Center(child: Icon(Icons.music_note)), // Adjust the width as needed // Download complete
          );
        } else if (snapshot.hasError) {
          return const Icon(Icons.error); // or retry button
        } else {
          return IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              setState(() {
                _downloadFuture = audioService.downloadFile(
                    widget.url, widget.title);
              });
            },
          );
        }
      },
    );
  }
}