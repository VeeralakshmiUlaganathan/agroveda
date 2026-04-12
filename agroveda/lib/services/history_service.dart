import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_model.dart';

class HistoryService {
  static const String key = "scan_history";

  static Future<void> saveHistory(HistoryModel model) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> historyList =
        prefs.getStringList(key) ?? [];

    historyList.add(jsonEncode(model.toJson()));

    await prefs.setStringList(key, historyList);
  }

  static Future<List<HistoryModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    List<String> historyList =
        prefs.getStringList(key) ?? [];

    return historyList
        .map((item) =>
            HistoryModel.fromJson(jsonDecode(item)))
        .toList()
        .reversed
        .toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}