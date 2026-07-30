import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

nullValidator(String hiveFieldName, dynamic value) {
  if (Hive.box("name").get(hiveFieldName) == null) {
    Hive.box("name").put(hiveFieldName, value);
  }
}

getValue(field){
  return Hive.box("name").get(field);
}

updateValue(field,value){
  Hive.box("name").put(field, value);
}

initializeHive() async {
  if (kIsWeb) {
    // Hive.init() is not strictly required for web if using Hive.openBox
    // but we can call it with null or just skip to openBox.
  } else {
    var p = await getApplicationDocumentsDirectory();
    Hive.init(p.path);
  }
  await Hive.openBox("name");
}
