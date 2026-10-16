import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

class AddPumpingBottomSheet extends StatefulWidget {
  const AddPumpingBottomSheet({super.key});

  @override
  State<AddPumpingBottomSheet> createState() => _AddPumpingBottomSheetState();
}

class _AddPumpingBottomSheetState extends State<AddPumpingBottomSheet> {
  static const _sides = ["Left", "Right"];

  String? _selectedSide;
  TimeOfDay _time = TimeOfDay.now();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    analyticService.screenView('add_pumping_sheet');
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  /// Geçerli süre (dakika, > 0); aksi halde null.
  int? get _duration {
    final v = int.tryParse(_durationController.text.trim());
    return (v == null || v <= 0) ? null : v;
  }

  bool get _isValid => _selectedSide != null && _duration != null;

  @override
  Widget build(BuildContext context) {
    final durationText = _durationController.text.trim();
    return ActivitySheetScaffold(
      kind: ActivityKind.pumping,
      title: 'Add Pumping',
      initialChildSize: 0.6,
      minChildSize: 0.4,
      onSave: _isValid ? _save : null,
      // Hatırlatıcı butonu başlıkta, kapatma butonunun yanında durur.
      actions: [
        IconButton(
          tooltip: 'Reminders',
          onPressed: () => openReminders(context, 'pumpingReminders'),
          style: IconButton.styleFrom(backgroundColor: AppColors.pinkTint),
          icon: const Icon(Icons.alarm, color: AppColors.deepCharcoal),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetSectionLabel("Pick side"),
          Row(
            children: [
              for (final side in _sides) ...[
                if (side != _sides.first) const SizedBox(width: 12),
                Expanded(
                  child: SideChoiceCard(
                    label: side,
                    icon: side == "Left"
                        ? Icons.keyboard_arrow_left
                        : Icons.keyboard_arrow_right,
                    selected: _selectedSide == side,
                    onTap: () => setState(() => _selectedSide = side),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TimeField(
                  label: "Start time",
                  value: formatHHmm(_time),
                  onTap: _pickTime,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 140,
                child: TextFormField(
                  controller: _durationController,
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: "Duration (min)",
                    errorText: durationText.isNotEmpty && _duration == null
                        ? 'Enter minutes > 0'
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await pick24hTime(context, _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final side = _selectedSide;
    final duration = _duration;
    if (side == null || duration == null) return;
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }

    final model = PumpingModel(
      isLeft: side == "Left",
      createdAt: DateTime.now().toIso8601String(),
      startTime: formatHHmm(_time),
      duration: duration,
    );

    try {
      await pumpingService.addPumping(model);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('addPumping failed: $e');
      if (!mounted) return;
      showSaveError(context);
    }
  }
}
