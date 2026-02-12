import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';

class SettingsViewModel extends ChangeNotifier {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;

  // Getters
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    final prefs = PreferencesService.instance;
    final hour = prefs.getReminderHour();
    final minute = prefs.getReminderMinute();
    _reminderEnabled = prefs.isReminderEnabled();
    _reminderTime = TimeOfDay(hour: hour, minute: minute);

    _isLoading = false;
    notifyListeners();
  }

  Future<String> toggleReminder(bool value) async {
    _reminderEnabled = value;
    notifyListeners();

    if (value) {
      final status = await Permission.notification.request();

      if (status.isGranted) {
        if (await Permission.scheduleExactAlarm.isDenied) {
          final alarmStatus = await Permission.scheduleExactAlarm.request();
          if (!alarmStatus.isGranted) {
            _reminderEnabled = false;
            notifyListeners();
            return 'Izin alarm ditolak. Pengingat tidak dapat diaktifkan.';
          }
        }

        await PreferencesService.instance.enableReminder();
        await NotificationService.instance.scheduleDailyReminder(
          _reminderTime.hour,
          _reminderTime.minute,
        );
        return 'Pengingat harian diaktifkan.';
      } else {
        _reminderEnabled = false;
        notifyListeners();
        return 'Izin notifikasi ditolak. Pengingat tidak dapat diaktifkan.';
      }
    } else {
      await PreferencesService.instance.disableReminder();
      await NotificationService.instance.cancelDailyReminder();
      return 'Pengingat harian dinonaktifkan.';
    }
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();

    await PreferencesService.instance.setReminderTime(
      time.hour,
      time.minute,
    );

    if (_reminderEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        time.hour,
        time.minute,
      );
    }
  }
}
