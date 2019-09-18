import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// void main() => runApp(MyApp());
Future main() async {
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: MyHomePage(title: 'Firebase Auth Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String username = 'Your Name';

  Future<FirebaseUser> _signInWithGoogle(BuildContext context) async {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text('Sign in button clicked'),
    ));
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print(credential);

    final FirebaseUser user =
        (await _auth.signInWithCredential(credential)).user;

    print(user);
    return user;
  }

  Future<void> _signOutWithGoogle(BuildContext context) async {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text('Sign in button clicked'),
    ));
    _auth.signOut();
    setState(() {
      username = 'Your name';
    });
  }

  TwitterLogin twitterInstance = new TwitterLogin(
    consumerKey: DotEnv().env['TWITTER_CONSUMERKEY'],
    consumerSecret: DotEnv().env['TWITTER_CONSUMERSECRET'],
  );

  Future<FirebaseUser> _signInWithTwitter(BuildContext context) async {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text('Sign in button clicked'),
    ));

    final TwitterLoginResult _twitterLoginResult =
        await twitterInstance.authorize();
    final TwitterSession _currentUserTwitterSession =
        _twitterLoginResult.session;
    final TwitterLoginStatus _twitterLoginStatus = _twitterLoginResult.status;

    AuthCredential _authCredential = TwitterAuthProvider.getCredential(
        authToken: _currentUserTwitterSession?.token ?? '',
        authTokenSecret: _currentUserTwitterSession?.secret ?? '');

    final FirebaseUser user =
        (await _auth.signInWithCredential(_authCredential)).user;

    // Navigator.push(
    //   context,
    //   new MaterialPageRoute(
    //     builder: (context) => new DetailedScreen(detailsUser: userInfoDetails),
    //   ),
    // );
    return user;
  }

  Future<Null> _signOutWithTwitter(BuildContext context) async {
    await twitterInstance.logOut();
    _auth.signOut();
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text('Sign out button clicked'),
    ));
    setState(() {
      username = 'Your name';
    });

    print('Signed out');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$username',
              style: Theme.of(context).textTheme.display1,
            ),
            StreamBuilder(
                stream: _auth.onAuthStateChanged,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return MaterialButton(
                      onPressed: () => _signOutWithGoogle(context),
                      color: Colors.red,
                      textColor: Colors.white,
                      child: Text('Signout'),
                    );
                  } else {
                    return MaterialButton(
                      onPressed: () => _signInWithGoogle(context)
                          .then((FirebaseUser user) => setState(() {
                                username = user.displayName;
                                print(username);
                              }))
                          .catchError((e) => print(e)),
                      color: Colors.white,
                      textColor: Colors.black,
                      child: Text('Login with Google'),
                    );
                  }
                }),
            StreamBuilder(
                stream: _auth.onAuthStateChanged,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return MaterialButton(
                      onPressed: () => _signOutWithTwitter(context),
                      color: Colors.red,
                      textColor: Colors.white,
                      child: Text('Signout'),
                    );
                  } else {
                    return MaterialButton(
                      onPressed: () => _signInWithTwitter(context)
                          .then((FirebaseUser user) => setState(() {
                                username = user.displayName;
                                print(username);
                              }))
                          .catchError((e) => print(e)),
                      color: Colors.white,
                      textColor: Colors.black,
                      child: Text('Login with Twitter'),
                    );
                  }
                }),
          ],
        ),
      ),
    );
  }
}
