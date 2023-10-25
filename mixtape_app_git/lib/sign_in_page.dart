import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/*
Used to sign users in. Tried to keep the same theme.

I debated just logging in all users as anon but did not like it in the end.
Anon is an easy skip that lets you have playlists.

No email validation. Good luck lol.
Supporting password resets which I don't really like but firebase makes it easy.

 */

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;  // Holds if you are authed

  Future<void> _signIn() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),  // remove whitespaces before and after the text but not just removing all of them
        password: _passwordController.text.trim(),
      );
      // Navigate to another page or show a success message if login is successful
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {// The error codes do a good job of stopping people from checking if you have an account somewhere. You just get invalid login creds back. But they break it with the signup
        case 'INVALID_LOGIN_CREDENTIALS':
          errorMessage = 'Error Issue with your Email or Password';
          break;
        default:
          errorMessage = 'An error occurred.';
      }

      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // For non-FirebaseAuth exceptions
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _signUp() async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Navigate to another page or show a success message if signup is successful
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      print(e);

      switch (e.code) {
        case 'email-already-in-use':  // Do we gas light them or don't let someone know they have an account
          errorMessage = 'The email address cannot be used.';  // Going with in the middle. Probably not the best user expirience
          break;
        case 'invalid-email': // Using this instead of email validating
          errorMessage = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email and Password accounts are not enabled.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = 'An error occurred.';
      }

      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // For non-FirebaseAuth exceptions
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }

  Future<void> _signInAnonymously() async {  // Skip auth is really just anon auth.
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _resetPassword() async {  // Don't really want to support but will
    try {
      await _auth.sendPasswordResetEmail(email: _emailController.text.trim(),);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
    }
  }
  // Contrary to thinking you could just use my app to flood password reset emails to anyone
  // It only sends if they have a valid account with the app

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Color(0xFF282828),
        title: Text('Sign In'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white24,
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            TextField( // Could put like restrictions on these fields but not super needed since I want to promote anonymous sign in.
              controller: _passwordController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white24,
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signIn,
              child: Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF282828),
              ),
            ),
            SizedBox(height: 20), // Why make a sign up page when you can have it here.
            ElevatedButton(
              onPressed: _signUp,
              child: Text('Sign Up'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF282828),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInAnonymously,
              child: Text('Skip'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF282828),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Forgot Password?'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF282828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}