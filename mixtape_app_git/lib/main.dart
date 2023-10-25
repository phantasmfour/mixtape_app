import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'album_list_screen.dart';
import 'playlists_screen.dart';
import 'audio_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'sign_in_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();  // This is for firebase too I think
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await JustAudioBackground.init(  // For background audio and notification center
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio', // Pretty sure it should be his ID
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(ChangeNotifierProvider( // This is for provider to track the state of AudioService
    create: (_) => AudioService(),
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mixtape Matrix',
      theme: ThemeData(
        primaryColor: Colors.grey[900],  // sets the app bar in the whole app for the default
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),  // Used to first launch the Authentication screen.
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // If they are now signed in show the main screen
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return SignInPage();
          } else {
            return MainScreen();
          }
        } else {  // Usually never seen
          // Return a loading indicator while Firebase initializes
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}


class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    // Add more keys if you have more tabs
  ];




  void _onItemTapped(int index) {
    // Lots of apps have this. Tap the page you want to go to and it will pop all the other stuff in your view to get to the original screen.
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
      // Little complicated but basically will navigate to the page on the bottom bar
        children: List<Widget>.generate(_navigatorKeys.length, (index) {
          return Positioned.fill(
            child: Offstage(
              offstage: _currentIndex != index,
              child: Navigator(
                key: _navigatorKeys[index],
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) {
                      switch (index) {
                        case 0:
                          return AlbumListScreen();
                        case 1:
                          return PlaylistsScreen();
                      // Add more cases for more tabs
                        default:
                          return SizedBox.shrink();
                      }
                    },
                  );
                },
              ),
            ),
          );
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(  // Bottom bar
        backgroundColor: Colors.grey[900], // Set the background color of the navigation bar
        selectedItemColor: Colors.white, // Set the selected item color
        unselectedItemColor: Colors.white70, // Set the unselected item color
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.album_rounded), label: 'Albums'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_add_check_outlined), label: 'Playlists'),
          // Add more items for more tabs
        ],
      ),
    );
  }
}
