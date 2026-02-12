import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/settings_viewmodel.dart';
import '../providers/theme_provider.dart';
import 'budget_recommendation_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadSettings();
    });
  }

  Future<void> _toggleReminder(SettingsViewModel viewModel, bool value) async {
    final message = await viewModel.toggleReminder(value);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectTime(SettingsViewModel viewModel) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: viewModel.reminderTime,
    );

    if (picked != null && picked != viewModel.reminderTime) {
      await viewModel.updateReminderTime(picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengingat diatur ulang ke ${picked.format(context)}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final viewModel = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengaturan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Tampilan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    title: const Text('Mode Gelap'),
                    subtitle: const Text('Gunakan tema gelap'),
                    secondary: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Pengingat',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    title: const Text('Pengingat Harian'),
                    subtitle: const Text(
                      'Ingatkan untuk mencatat pengeluaran setiap hari',
                    ),
                    value: viewModel.reminderEnabled,
                    onChanged: (value) => _toggleReminder(viewModel, value),
                    secondary: const Icon(Icons.notifications_active_rounded),
                  ),
                ),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: const Text('Waktu Pengingat'),
                    subtitle: Text(
                      viewModel.reminderTime.format(context),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    leading: const Icon(Icons.access_time_rounded),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: viewModel.reminderEnabled
                        ? () => _selectTime(viewModel)
                        : null,
                    enabled: viewModel.reminderEnabled,
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Budget',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    title: const Text('Atur Budget Bulanan'),
                    subtitle: const Text('Kelola budget dan rekomendasi'),
                    leading: const Icon(Icons.account_balance_wallet_rounded),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BudgetRecommendationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Tentang',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text('Versi Aplikasi'),
                        subtitle: Text('1.0.0'),
                        leading: Icon(Icons.info_outline_rounded),
                      ),
                      Divider(height: 1),
                      ListTile(
                        title: Text('Tentang Aplikasi'),
                        subtitle: Text(
                          'Aplikasi pengelolaan pengeluaran offline',
                        ),
                        leading: Icon(Icons.apps_rounded),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }
}
