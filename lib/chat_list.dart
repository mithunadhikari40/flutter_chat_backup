import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat/chat.dart';
import 'package:flutter_chat/const.dart';
import 'package:flutter_chat/login.dart';
import 'package:flutter_chat/settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MainScreen extends StatefulWidget {
  final String currentUserId;

  MainScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => MainScreenState(currentUserId: currentUserId);
}

class MainScreenState extends State<MainScreen> {
  MainScreenState({Key key, @required this.currentUserId});

  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = new FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

//  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
  ];

  @override
  void initState() {
    super.initState();

    setupNotifications();
  }

  Future registerNotification() async {
    if (Platform.isIOS) firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          print('onMessage: $message');
         return showNotification(message);
         },
//        onBackgroundMessage: backgroundMessageHandler,
        onResume: (Map<String, dynamic> message) {
          print('onResume: $message');

          return  showNotification(message);

         },
        onLaunch: (Map<String, dynamic> message) {
          print('onLaunch: $message');
        return  showNotification(message);
        });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      Firestore.instance
          .collection('users')
          .document(currentUserId)
          .updateData({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  Future configLocalNotification() async {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(onDidReceiveLocalNotification: onDidRecieveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
     await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Settings()));
    }
  }

  Future showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? androidId : iosId,
      'Flutter chat application',
      'Flutter chat app using local notification',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(presentAlert: true, presentSound: true);
    var notificationDetail = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      message["notification"]['title'].toString(),
      message["notification"]['body'].toString(),
      notificationDetail,
      payload: json.encode(
        message,
      ),
    );

//    Navigator.push(navigatorKey.currentContext, MaterialPageRoute(builder: (_) => DeeplyNestedView()));

    /*
    {notification: {body: notification text, title: title}, data: {peerId : https://github.com/moda20/flutter-tunein.git, click_action: FLUTTER_NOTIFICATION_CLICK}}
     */
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Exit app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Are you sure to exit app?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'YES',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
//    await googleSignIn.disconnect();
//    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'MAIN',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: <Widget>[
            PopupMenuButton<Choice>(
              onSelected: onItemMenuPress,
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                      value: choice,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            choice.icon,
                            color: primaryColor,
                          ),
                          Container(
                            width: 10.0,
                          ),
                          Text(
                            choice.title,
                            style: TextStyle(color: primaryColor),
                          ),
                        ],
                      ));
                }).toList();
              },
            ),
          ],
        ),
        body: WillPopScope(
          child: Stack(
            children: <Widget>[
              // List
              Container(
                child: StreamBuilder(
                  stream: Firestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      print(
                          "The all the data from firebase does not have any data in users");
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                        ),
                      );
                    } else {
                      print(
                          "The all the data from firebase  have any data in users");

                      return ListView.builder(
                        padding: EdgeInsets.all(10.0),
                        itemBuilder: (context, index) =>
                            buildItem(context, snapshot.data.documents[index]),
                        itemCount: snapshot.data.documents.length,
                      );
                    }
                  },
                ),
              ),

              // Loading
              Positioned(
                child: isLoading
                    ? Container(
                        child: Center(
                          child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(themeColor)),
                        ),
                        color: Colors.white.withOpacity(0.8),
                      )
                    : Container(),
              )
            ],
          ),
          onWillPop: onBackPress,
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    var data = document.data;
    print("The all data from the firebase firestore are ${json.encode(data)}");
    var userId = document["id"];

    print("The user id document $userId and current user id $currentUserId");

    if (document['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: document['photoUrl'] != null
                    ? CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          width: 50.0,
                          height: 50.0,
                          padding: EdgeInsets.all(15.0),
                        ),
                        imageUrl: document['photoUrl'],
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: greyColor,
                      ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          'Nickname: ${document['nickname']}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      Container(
                        child: Text(
                          'About me: ${document['aboutMe'] ?? 'Not available'}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
              FutureBuilder(
                future: buildUnreadMessages(document['id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  var count = snapshot.data;

                  return buildUnreadMessageNo(count);
                },
              )
            ],
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chat(
                  peerId: document.documentID,
                  peerAvatar: document['photoUrl'],
                ),
              ),
            );
          },
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }

  Future<int> buildUnreadMessages(String userId) async {
    try {
      final DocumentSnapshot snapshot = await Firestore.instance
          .collection('unread_messages')
          .document('$userId-$currentUserId')
          .get();

      int size = snapshot["size"];
      print("The size of the messages $size");
      return size;
    } catch (e) {
      print("Exception while getting unread messages $e");
      return 0;
    }
  }

  Widget buildUnreadMessageNo(int count) {
    if (count < 1) {
      return Container();
    }

    return SizedBox.fromSize(
      size: Size(32, 32), // button width and height
      child: ClipOval(
        child: Container(
            alignment: Alignment.center,
            color: Colors.red, // button color
            child: Text("$count")),
      ),
    );
  }

  Future onSelectNotification(String payload) async {

    var message = jsonDecode(payload);
    Fluttertoast.showToast(
        msg: "The payload is ${message == null ? 'null' : message}");



    Future.delayed(Duration.zero, () => false);
//
    if (message["data"] != null && message["data"]["peerId"] != null) {
      await navigatorKey.currentState.push(
        MaterialPageRoute(
          builder: (_) => Chat(
            peerId: message["data"]["peerId"],
          ),
        ),
      );
    }
//    await Future.delayed(Duration.zero);
//    print("Notification payload on click notificatoin is $payload");
  }

  void setupNotifications()  async {
     await configLocalNotification();
    registerNotification();
  }

//  Future<String> handleSignIn() async {
//    final FirebaseAuth _auth = FirebaseAuth.instance;
//    SharedPreferences prefs;
//
//    FirebaseUser currentUser;
//    prefs = await SharedPreferences.getInstance();
//
//
//    AuthResult authResult = await _auth.signInWithEmailAndPassword(
//        email: "sudip@unlimit.com", password: "sudip123");
//    print("The auth result is $authResult");
//
//    FirebaseUser firebaseUser = authResult.user;
//
//    if (firebaseUser != null) {
//      // Check is already sign up
//      final QuerySnapshot result = await Firestore.instance
//          .collection('users')
//          .where('id', isEqualTo: firebaseUser.uid)
//          .getDocuments();
//      final List<DocumentSnapshot> documents = result.documents;
//      if (documents.length == 0) {
//        // Update data to server if new user
//        Firestore.instance
//            .collection('users')
//            .document(firebaseUser.uid)
//            .setData({
//          'nickname': firebaseUser.displayName,
//          'photoUrl': firebaseUser.photoUrl,
//          'id': firebaseUser.uid,
//          'createdAt': DateTime
//              .now()
//              .millisecondsSinceEpoch
//              .toString(),
//          'chattingWith': null
//        });
//
//        // Write data to local
//        currentUser = firebaseUser;
//        await prefs.setString('id', currentUser.uid);
//        await prefs.setString('nickname', currentUser.displayName);
//        await prefs.setString('photoUrl', currentUser.photoUrl);
//      } else {
//        // Write data to local
//        await prefs.setString('id', documents[0]['id']);
//        await prefs.setString('nickname', documents[0]['nickname']);
//        await prefs.setString('photoUrl', documents[0]['photoUrl']);
//        await prefs.setString('aboutMe', documents[0]['aboutMe']);
//      }
//
//      return firebaseUser.uid;
//    } else {
//      return null;
//    }
//  }

  Future onDidRecieveLocalNotification(
      int id, String title, String body, String payload) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text(title),
        content: new Text(body),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: new Text('Ok'),
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await Fluttertoast.showToast(
                  msg: "Notification Clicked",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  timeInSecForIos: 1,
                  backgroundColor: Colors.black54,
                  textColor: Colors.white,
                  fontSize: 16.0
              );
            },
          ),
        ],
      ),
    );
  }


}

Future<dynamic> backgroundMessageHandler(Map<String, dynamic> message) {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }
  return Future.delayed(Duration.zero);

  // Or do other work.
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}
