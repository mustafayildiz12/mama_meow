import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
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
      // Hatırlatıcı butonu standart başlığın altında sağda durur.
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
        child: Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: 'Reminders',
            onPressed: () => openReminders(context, 'pumpingReminders'),
            style: IconButton.styleFrom(backgroundColor: AppColors.pinkTint),
            icon: const Icon(Icons.alarm, color: AppColors.deepCharcoal),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel("Pick side"),
          Row(
            children: [
              for (final side in _sides) ...[
                if (side != _sides.first) const SizedBox(width: 12),
                Expanded(
                  child: _SideCard(
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

/// Sheet bölüm başlığı (15/w700, koyu kömür).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: 15,
          color: AppColors.deepCharcoal,
        ),
      ),
    );
  }
}

/// Büyük taraf kartı: seçiliyken beyaz + 2 px berry çerçeve + onay rozeti,
/// değilken pembe zemin.
class _SideCard extends StatelessWidget {
  const _SideCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusCard);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? AppColors.cottonWhite : AppColors.pinkTint,
                borderRadius: radius,
                border: Border.all(
                  color: selected ? AppColors.activeBerry : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 24,
                    color: selected
                        ? AppColors.activeBerry
                        : AppColors.charcoalSoft,
                  ),
                  const SizedBox(height: 6),
                  Text(label, style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
            if (selected)
              const Positioned(top: 12, right: 12, child: _CheckBadge()),
          ],
        ),
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.activeBerry,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 14, color: AppColors.cottonWhite),
    );
  }
}
