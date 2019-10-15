import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_twitter_login/flutter_twitter_login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:provider/provider.dart';

// void main() => runApp(MyApp());
Future main() async {
  await DotEnv().load('.env');
  // runApp(MyApp());
  runApp(
    ChangeNotifierProvider(
      builder: (context) => _AuthChangeNotifier(),
      child: new MaterialApp(
        title: 'Navigation with Routes',
        routes: <String, WidgetBuilder>{
          '/': (_) => new Splash(),
          '/login': (_) => new Login(),
          '/home': (_) => new Home(),
          '/next': (_) => new Next(),
        },
      ),
    ),
  );

  // runApp(new MaterialApp(
  //   title: 'Navigation with Routes',
  //   routes: <String, WidgetBuilder>{
  //     '/': (_) => new Splash(),
  //     '/login': (_) => new Login(),
  //     '/home': (_) => new Home(),
  //     '/next': (_) => new Next(),
  //   },
  // ));
}

// String userId;

// 認証とユーザのステート管理
class _AuthChangeNotifier with ChangeNotifier {
  // 認証関連の情報
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TwitterLogin twitterInstance = new TwitterLogin(
    consumerKey: DotEnv().env['TWITTER_CONSUMERKEY'],
    consumerSecret: DotEnv().env['TWITTER_CONSUMERSECRET'],
  );

  // ユーザ情報など
  String username;
  FirebaseUser _user;
  AuthCredential _credential;

  String userId;

  String get getDisplayUid => _user.uid;

  // google認証
  Future<FirebaseUser> _signInWithGoogle() async {
    // Future<FirebaseUser> _signInWithGoogle(BuildContext context) async {
    // Scaffold.of(context).showSnackBar(new SnackBar(
    //   content: new Text('Sign in button clicked'),
    // ));
    final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    _credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print(_credential);
    _user = (await _auth.signInWithCredential(_credential)).user;
    print(_user.uid);
    this.userId = _user.uid;
    notifyListeners();
    return _user;
  }

  // twitter認証
  Future<FirebaseUser> _signInWithTwitter(BuildContext context) async {
    final TwitterLoginResult _twitterLoginResult =
        await twitterInstance.authorize();
    final TwitterSession _currentUserTwitterSession =
        _twitterLoginResult.session;
    final TwitterLoginStatus _twitterLoginStatus = _twitterLoginResult.status;
    _credential = TwitterAuthProvider.getCredential(
        authToken: _currentUserTwitterSession?.token ?? '',
        authTokenSecret: _currentUserTwitterSession?.secret ?? '');
    print(_credential);
    _user = (await _auth.signInWithCredential(_credential)).user;
    print(_user.uid);
    userId = _user.uid;
    notifyListeners();
    return _user;
  }

  // サインアウト
  Future<void> _signOut(BuildContext context) async {
    // await twitterInstance.logOut();
    print(userId);
    _auth.signOut();
    _user = null;
    _credential = null;
    username = 'Your name';
    userId = null;
    notifyListeners();
  }

  void uid() {
    // increment()が呼ばれると、Listenerたちに変更を通知する
    notifyListeners();
  }
}

// スプラッシュ画面
class Splash extends StatefulWidget {
  @override
  _SplashState createState() => new _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    new Future.delayed(const Duration(seconds: 1))
        .then((value) => handleTimeout());
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        // スプラッシュアニメーション
        child: const CircularProgressIndicator(
          backgroundColor: Colors.black,
        ),
      ),
    );
  }

  void handleTimeout() {
    // ログイン画面へ
    Navigator.of(context).pushReplacementNamed("/login");
  }
}

// googleログインボタン
class GoogleSigninWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GoogleSignInButton(
      onPressed: () => Provider.of<_AuthChangeNotifier>(context, listen: true)
          ._signInWithGoogle()
          .then((FirebaseUser user) =>
              Navigator.of(context).pushReplacementNamed("/home"))
          .catchError((e) => print(e)),
      darkMode: true, // default: false
    );
  }
}

// twitterログインボタン
class TwitterSigninWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TwitterSignInButton(
      onPressed: () => Provider.of<_AuthChangeNotifier>(context, listen: true)
          ._signInWithTwitter(context)
          .then((FirebaseUser user) =>
              Navigator.of(context).pushReplacementNamed("/home"))
          .catchError((e) => print(e)),
    );
  }
}

// ログアウトボタン
class SignoutWisget extends StatelessWidget {
  Widget build(BuildContext context) {
    return RaisedButton(
      child: const Text("Logout"),
      onPressed: () {
        // 確認ダイアログ表示
        showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
              content: const Text('Do you want logout?'),
              actions: <Widget>[
                new FlatButton(
                  child: const Text('No'),
                  onPressed: () {
                    // 引数をfalseでダイアログ閉じる
                    Navigator.of(context).pop(false);
                  },
                ),
                new FlatButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    // 引数をtrueでダイアログ閉じる
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ).then<void>((aBool) {
          // ダイアログがYESで閉じられたら...
          if (aBool) {
            //  ログアウト処理
            Provider.of<_AuthChangeNotifier>(context, listen: true)
                ._signOut(context);
            // 画面をすべて除いてスプラッシュを表示
            Navigator.pushAndRemoveUntil(
                context,
                new MaterialPageRoute(builder: (context) => new Splash()),
                (_) => false);
          }
        });
      },
    );
  }
}

// ログイン画面
class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ここからChangeNotifierを下層に渡す
    return ChangeNotifierProvider<_AuthChangeNotifier>(
      builder: (_) => _AuthChangeNotifier(),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          GoogleSigninWidget(),
          TwitterSigninWidget(),
        ],
      ),
    );
  }
}

// ホーム画面
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<_AuthChangeNotifier>(context);
    print(auth.userId);

    return new Scaffold(
      appBar: new AppBar(
        title: const Text("Home"),
      ),
      body: new Center(
        child: new RaisedButton(
          child: Text('Launch Next Screen'),
          onPressed: () {
            // その他の画面��
            Navigator.of(context).pushNamed("/next");
          },
        ),
      ),
    );
  }
}

// 詳細画面
class Next extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<_AuthChangeNotifier>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // userId != null ? Text(userId) : Container(),
        SignoutWisget(),
      ],
    );
  }
}
