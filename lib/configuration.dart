import 'package:flutter/material.dart';

class Config{
    static final Config _instance = Config._internal();

    static const String appName = "DFE-ChViewer";
    static const String appVersion = "1.0.0";

    Config._internal();
    factory Config.getInstance() => _instance;


    ColorConfig color   = ColorConfig.dark;
    
    final String getUserAgent = "Monazilla/1.0.0 $appName/$appVersion";
    final String postUserAgent= "Monazilla/1.0.0 $appName/$appVersion";
}

class _Color extends Color{
    const _Color(int colorCode):
        super.fromARGB(
            255,
            (colorCode>>16)&0xff,
            (colorCode>> 8)&0xff,
             colorCode     &0xff
        );
}

class ColorConfig{
    final Color primary;
    final Color onPrimary;
    final Color background;
    final Color foreground;
    final Color foreground2;
    final Color foreground3;

    const ColorConfig(
        this.primary,
        this.onPrimary,
        this.background,
        this.foreground,
        this.foreground2,
        this.foreground3
    );

    static const ColorConfig light = ColorConfig(
        // Colors.blueGrey,
        _Color(0x5f7f8f),
        // Colors.white,
        _Color(0xffffff),
        // Colors.white,
        _Color(0xffffff),
        // Colors.black,
        _Color(0x0f0f0f),
        // Colors.black87,
        _Color(0x3f3f3f),
        // Colors.black54
        _Color(0x6f6f6f)
    );
    static const ColorConfig dark = ColorConfig(
        _Color(0x7f7f7f),
        _Color(0xffffff),
        _Color(0x1f1f1f),
        _Color(0xefefef),
        _Color(0xbfbfbf),
        _Color(0x8f8f8f)
    );
}
