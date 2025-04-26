import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class Store {
  const Store._();

  static const String themeMode = 'theme_mode';

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  }

  static Future<void> setThemeMode(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(themeMode, value);
  }

  static Future<String> getThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(themeMode) ?? 'system';
  }

  static Future<void> setNameRegistered(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('first_name_registering', value);
  }

  static Future<String> getNameRegistered() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('first_name_registering') ?? '';
  }

  static Future<void> setEmailRegistered(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('email_registering', value);
  }

  static Future<String> getEmailRegistered() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('email_registering') ?? '';
  }

  static Future<String> getMessagesChatWithAI() async {
    final prefs = await SharedPreferences.getInstance();
    return  prefs.getString('chat_messages_with_meta_ai') ?? '';
  }
  static Future<void> saveMessagesWithAI(List<Map<String, String>> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_messages_with_meta_ai', jsonEncode(messages));
  }

}
