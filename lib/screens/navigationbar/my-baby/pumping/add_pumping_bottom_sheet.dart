import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/models/activities/pumping_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';

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
      initialChildSize: 0.5,
      minChildSize: 0.4,
      gradient: const [Color(0xFFFFCAB0), Color(0xFFFFD3A5)],
      onSave: _isValid ? _save : null,
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
                onPressed: () => openReminders(context, 'pumpingReminders'),
                icon: const Icon(Icons.alarm),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ChipPickerSection<String>(
              title: "Pick Side",
              items: _sides,
              value: _selectedSide,
              style: ChipTileStyle.orangeLarge,
              onChanged: (value) => setState(() => _selectedSide = value),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TimeField(
                  label: "Start Time",
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
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
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
