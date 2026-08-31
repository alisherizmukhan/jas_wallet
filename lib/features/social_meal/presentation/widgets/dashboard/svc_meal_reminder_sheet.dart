import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:jaswallet_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Meal reminders configuration sheet.
class SVCMealReminderSheet extends StatefulWidget {
  const SVCMealReminderSheet({super.key});

  @override
  State<SVCMealReminderSheet> createState() => _SVCMealReminderSheetState();
}

class _SVCMealReminderSheetState extends State<SVCMealReminderSheet> {
  bool _breakfast = false;
  bool _lunch = false;
  bool _dinner = false;
  int _offsetMinutes = 30;
  bool _loaded = false;

  static const _kBreakfast = 'svc_reminder_breakfast';
  static const _kLunch = 'svc_reminder_lunch';
  static const _kDinner = 'svc_reminder_dinner';
  static const _kOffsetMinutes = 'svc_reminder_offset';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _breakfast = prefs.getBool(_kBreakfast) ?? false;
      _lunch = prefs.getBool(_kLunch) ?? false;
      _dinner = prefs.getBool(_kDinner) ?? false;
      _offsetMinutes = prefs.getInt(_kOffsetMinutes) ?? 30;
      _loaded = true;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isLight ? AppColors.borderGrey : AppColors.borderDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            l10n.svc_mealReminders,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.svc_reminderDescription,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          if (!_loaded)
            const Center(child: AppLoader())
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.svc_notifyBefore,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButton<int>(
                  value: _offsetMinutes,
                  underline: SizedBox(),
                  icon: AppIcon(
                    AppIcons.chevronDown,
                    color: AppColors.primary,
                  ),
                  items: [
                    DropdownMenuItem(value: 15, child: Text(l10n.svc_time15m)),
                    DropdownMenuItem(value: 30, child: Text(l10n.svc_time30m)),
                    DropdownMenuItem(value: 45, child: Text(l10n.svc_time45m)),
                    DropdownMenuItem(value: 60, child: Text(l10n.svc_time60m)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _offsetMinutes = v);
                      _saveInt(_kOffsetMinutes, v);
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.svc_reminderBreakfast),
              subtitle: const Text('08:30'),
              value: _breakfast,
              onChanged: (v) {
                setState(() => _breakfast = v);
                _saveBool(_kBreakfast, v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.svc_reminderLunch),
              subtitle: const Text('11:00'),
              value: _lunch,
              onChanged: (v) {
                setState(() => _lunch = v);
                _saveBool(_kLunch, v);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.svc_reminderDinner),
              subtitle: const Text('17:00'),
              value: _dinner,
              onChanged: (v) {
                setState(() => _dinner = v);
                _saveBool(_kDinner, v);
              },
            ),
          ],
        ],
      ),
    );
  }
}
