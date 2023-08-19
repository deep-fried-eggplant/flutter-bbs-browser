import 'package:flutter/material.dart';

class Config{
    static final Config _instance = Config._internal();

    Config._internal();
    factory Config.getInstance() => _instance;

    ColorConfig color   = ColorConfig.light;
    
    final String getUserAgent = "Monazilla/1.0.0 DFE-ChViewer/1.0.0";
    final String postUserAgent= "Monazilla/1.0.0 DFE-ChViewer/1.0.0";
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
        Colors.blueGrey,
        Colors.white,
        Colors.white,
        Colors.black,
        Colors.black87,
        Colors.black54
    );
    static const ColorConfig dark = ColorConfig(
        Colors.black54,
        Colors.white,
        Colors.black87,
        Colors.white,
        Colors.white70,
        Colors.white60
    );
}