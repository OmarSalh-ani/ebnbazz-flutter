import 'dart:io';

bool get isAndroid => Platform.isAndroid;

bool get isIOS => Platform.isIOS;

bool get isMobile => Platform.isAndroid || Platform.isIOS;
