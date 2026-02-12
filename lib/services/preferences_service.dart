import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  SharedPreferences? _prefs;

  PreferencesService._init();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Reminder time
  Future<void> setReminderTime(int hour, int minute) async {
    await _prefs?.setInt('reminder_hour', hour);
    await _prefs?.setInt('reminder_minute', minute);
    await _prefs?.setBool('reminder_enabled', true);
  }

  int getReminderHour() {
    return _prefs?.getInt('reminder_hour') ?? 20; // Default 20:00
  }

  int getReminderMinute() {
    return _prefs?.getInt('reminder_minute') ?? 0;
  }

  bool isReminderEnabled() {
    return _prefs?.getBool('reminder_enabled') ?? false;
  }

  Future<void> disableReminder() async {
    await _prefs?.setBool('reminder_enabled', false);
  }

  Future<void> enableReminder() async {
    await _prefs?.setBool('reminder_enabled', true);
  }

  // Dark mode
  Future<void> setDarkMode(bool isDark) async {
    await _prefs?.setBool('dark_mode', isDark);
  }

  bool isDarkMode() {
    return _prefs?.getBool('dark_mode') ?? false;
  }
}
