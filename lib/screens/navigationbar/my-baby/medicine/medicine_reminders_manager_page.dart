import 'package:flutter/material.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/reminders/reminder_manager_page.dart';
import 'package:mama_meow/service/reminders/reminder_config.dart';

class MedicineRemindersManagerPage extends StatelessWidget {
  const MedicineRemindersManagerPage({super.key});

  @override
  Widget build(BuildContext context) =>
      ReminderManagerPage(config: ReminderConfig.medicine);
}
