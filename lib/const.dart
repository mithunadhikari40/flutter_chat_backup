import 'dart:ui';

import 'package:flutter/material.dart';

final themeColor = Color(0xfff5a623);
final primaryColor = Color(0xff203152);
final greyColor = Color(0xffaeaeae);
final greyColor2 = Color(0xffE8E8E8);


const String androidId = "np.com.mithun.flutter_chat";
const String iosId = "np.com.mithun.flutterChat";
 const String encryptionKey ="nepal123";


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(debugLabel:"navigator");

// type: 0 = text, 1 = image, 2 = sticker

const int CHAT_TEXT = 0;
const int CHAT_IMAGE= 1;
const int CHAT_STICKER = 2;

