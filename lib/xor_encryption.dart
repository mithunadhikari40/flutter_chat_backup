
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chat/const.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';


class XorEncryption {


  static String encrypt(String data) {
    var charCount = data.length;
//     var charCount = 0x100;
    var encrypted = [];
    var kp = 0;
    var kl = encryptionKey.length - 1;

    for (var i = 0; i < charCount; i++) {
      var other = data[i].codeUnits[0] ^ encryptionKey[kp].codeUnits[0];
      encrypted.insert(i, other);
      kp = (kp < kl) ? (++kp) : (0);
    }
    return dataToString(encrypted);
  }

  static String decrypt(data) {
    return encrypt(data);
  }

  static String dataToString(data) {
    var s = "";
    for (var i = 0; i < data.length; i++) {
      s += String.fromCharCode(data[i]);
    }
    return s;
  }



  static Future<File> encryptFile(File file) async{
    List<int> imageBytes = await file.readAsBytes();
    String base64Image = base64Encode(imageBytes);
    String encrypted = encrypt(base64Image);
    String path = file.path;
    String fileName = basename(path);
    int index = fileName.lastIndexOf(".");
    String extension = fileName.substring(index);


    Uint8List bytes = base64.decode(encrypted);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File newFile = File(
        "$dir/" + DateTime.now().millisecondsSinceEpoch.toString() + extension);
    await newFile.writeAsBytes(bytes);
    return newFile;
  }

  static Future<File> decryptFile(File file){
    return encryptFile(file);

  }
}

typedef T VarArgsCallback<T>(List<dynamic> args, Map<String, dynamic> kwargs);

class VarArgsFunction<T> {
  final VarArgsCallback<T> callback;
  static var _offset = 'Symbol("'.length;

  VarArgsFunction(this.callback);

  T call() => callback([], {});

  @override
  dynamic noSuchMethod(Invocation inv) {
    return callback(
      inv.positionalArguments,
      inv.namedArguments.map(
            (_k, v) {
          var k = _k.toString();
          return MapEntry(k.substring(_offset, k.length - 2), v);
        },
      ),
    );
  }
}

otherFunction() {
  dynamic myFunc = VarArgsFunction((args, kwargs) {
    print('Got args: $args, kwargs: $kwargs');
  });
  myFunc(1, 2, x: true, y: false); // Got args: [1, 2], kwargs: {x: true, y: false}
}