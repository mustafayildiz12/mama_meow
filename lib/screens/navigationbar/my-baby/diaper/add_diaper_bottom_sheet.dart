import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/models/activities/diaper_model.dart';
import 'package:mama_meow/models/dummy/dummy_solid_list.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';

class AddDiaperBottomSheet extends StatefulWidget {
  const AddDiaperBottomSheet({super.key});

  @override
  State<AddDiaperBottomSheet> createState() => _AddDiaperBottomSheetState();
}

class _AddDiaperBottomSheetState extends State<AddDiaperBottomSheet> {
  String? _selectedDiaper;
  TimeOfDay _time = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    analyticService.screenView('add_diaper_sheet');
  }

  @override
  Widget build(BuildContext context) {
    return ActivitySheetScaffold(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      gradient: [Colors.green.shade200, Colors.tealAccent.shade200],
      onSave: _selectedDiaper != null ? _save : null,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => openReminders(context, 'diaperReminders'),
                icon: const Icon(Icons.alarm_add),
              ),
            ],
          ),
          ChipPickerSection<String>(
            title: "Add Diaper",
            items: kDummyDiapers,
            value: _selectedDiaper,
            onChanged: (value) => setState(() => _selectedDiaper = value),
          ),
          const SizedBox(height: 24),
          TimeField(value: formatHHmm(_time), onTap: _pickTime),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await pick24hTime(context, _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final diaper = _selectedDiaper;
    if (diaper == null) return;
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }

    final model = DiaperModel(
      diaperName: diaper,
      createdAt: DateTime.now().toIso8601String(),
      diaperTime: formatHHmm(_time),
    );

    try {
      await diaperService.addDiaper(model);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('addDiaper failed: $e');
      if (!mounted) return;
      showSaveError(context);
    }
  }
}
