import 'package:shared_preferences/shared_preferences.dart';

class PrinterPref {

  static const key = "default_printer";

  static Future<void> save(String mac) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(key, mac);
  }

  static Future<String?> load() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(key);
  }

}