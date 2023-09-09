import 'package:flutter/foundation.dart';
import 'package:charset_converter/charset_converter.dart';

Future<String> sjisToUtf8(Uint8List bytes) async{
    return await CharsetConverter.decode("shift_jis",bytes);
}
Future<Uint8List> utf8Tosjis(String str) async{
    return await CharsetConverter.encode("shift_jis", str);
}