import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/reminders/reminders.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

/// Nursing side options
class NursingSides {
  static const List<String> sides = ['Left', 'Right'];
}

/// Feeding type options
class FeedingTypes {
  static const List<String> types = ['Nursing', 'Bottle'];
}

/// Milk type options (for bottle feeding)
class MilkTypes {
  static const List<String> types = [
    'Breast milk',
    'Formula',
    'Tube feeding',
    'Cow milk',
    'Goat milk',
    'Soy milk',
    'Other',
  ];
}

/// Amount type options
class AmountTypes {
  static const List<String> types = ['oz', 'ml'];
}

class AddNursingBottomSheet extends StatefulWidget {
  const AddNursingBottomSheet({super.key});

  @override
  State<AddNursingBottomSheet> createState() => _AddNursingBottomSheetState();
}

class _AddNursingBottomSheetState extends State<AddNursingBottomSheet> {
  String? _selectedSide;
  String? _selectedFeedingType;
  String? _selectedMilkType;
  String _selectedAmountType = AmountTypes.types.first;

  TimeOfDay _selectedTime = TimeOfDay.now();
  final TextEditingController _durationController = TextEditingController();
  double _amount = 0.0;

  /// Etkin nursing hatırlatıcısı var mı (alarm ikonunun rengi için).
  bool _hasReminder = false;

  bool get _isBottle => _selectedFeedingType == 'Bottle';

  @override
  void initState() {
    super.initState();
    analyticService.screenView('add_nursing_sheet');
    _loadReminderState();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadReminderState() async {
    final active = await ReminderStore.of(ReminderCategory.nursing).hasActive();
    if (mounted) setState(() => _hasReminder = active);
  }

  Future<void> _openReminders() async {
    await openReminders(context, 'nursingReminders');
    await _loadReminderState(); // dönüşte ikon rengini tazele
  }

  Future<void> _selectTime() async {
    final picked = await pick24hTime(context, _selectedTime);
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  bool _isFormValid() {
    switch (_selectedFeedingType) {
      case 'Nursing':
        return _selectedSide != null;
      case 'Bottle':
        return _selectedMilkType != null && _amount > 0;
      default:
        return false;
    }
  }

  double get _maxAmount => _selectedAmountType == 'oz' ? 12.0 : 350.0;

  /// Tür değişince diğer türe ait seçimler sıfırlanır (eski değer kaydedilmesin).
  void _onFeedingTypeChanged(String type) {
    setState(() {
      if (type != _selectedFeedingType) {
        _selectedSide = null;
        _selectedMilkType = null;
        _amount = 0.0;
      }
      _selectedFeedingType = type;
    });
  }

  /// Birim değişince miktar sıfırlanır.
  void _onAmountTypeChanged(String value) {
    setState(() {
      _selectedAmountType = value;
      _amount = 0.0;
    });
  }

  Future<void> _saveNursing() async {
    final type = _selectedFeedingType;
    if (type == null || !_isFormValid()) return;
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }

    // Taraf yalnızca emzirmede, miktar/süt türü yalnızca biberonda yazılır.
    final isBottle = type == 'Bottle';
    final nursing = NursingModel(
      side: isBottle ? "" : (_selectedSide ?? ""),
      startTime: formatHHmm(_selectedTime),
      duration: int.tryParse(_durationController.text) ?? 0,
      feedingType: type.toLowerCase(),
      milkType: isBottle ? _selectedMilkType : null,
      amountType: _selectedAmountType,
      amount: isBottle ? _amount : 0.0,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await nursingService.addNursing(nursing);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Nursing record saved successfully')),
      );
    } catch (e) {
      debugPrint('addNursing failed: $e');
      if (!mounted) return;
      showSaveError(context);
    }
  }

  IconData _getIconForSide(String side) {
    switch (side.toLowerCase()) {
      case 'left':
        return Icons.keyboard_arrow_left;
      case 'right':
        return Icons.keyboard_arrow_right;
      default:
        return Icons.center_focus_strong;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivitySheetScaffold(
      kind: ActivityKind.nursing,
      title: 'Add Nursing',
      subtitle: DateFormat('EEEE, d MMM').format(DateTime.now()),
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      attachScrollController: true,
      onSave: _isFormValid() ? _saveNursing : null,
      // Hatırlatıcı butonu başlıkta, kapatma butonunun yanında durur.
      actions: [
        IconButton(
          tooltip: 'Reminders',
          onPressed: _openReminders,
          style: IconButton.styleFrom(backgroundColor: AppColors.pinkTint),
          icon: Icon(
            Icons.alarm_add,
            color: _hasReminder
                ? AppColors.activeBerry
                : AppColors.deepCharcoal,
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetSectionLabel('Feeding type'),
          SheetPillToggle(
            options: FeedingTypes.types,
            value: _selectedFeedingType,
            onChanged: _onFeedingTypeChanged,
          ),
          const SizedBox(height: 24),

          if (_selectedFeedingType == 'Nursing') ...[
            const SheetSectionLabel('Side'),
            Row(
              children: [
                for (final side in NursingSides.sides) ...[
                  if (side != NursingSides.sides.first)
                    const SizedBox(width: 12),
                  Expanded(
                    child: SideChoiceCard(
                      label: side,
                      icon: _getIconForSide(side),
                      selected: _selectedSide == side,
                      onTap: () => setState(() => _selectedSide = side),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],

          if (_isBottle) ...[
            const SheetSectionLabel('Milk type'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final milk in MilkTypes.types)
                  ChoiceChip(
                    label: Text(milk),
                    selected: _selectedMilkType == milk,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedMilkType = milk),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SheetSectionCard(title: 'Amount', child: _amountPicker()),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Expanded(
                child: TimeField(
                  value: formatHHmm(_selectedTime),
                  onTap: _selectTime,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Duration (min)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountPicker() {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Büyük miktar göstergesi: beyaz, ince çizgili kutu.
            Expanded(
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.cottonWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _amount.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: AppColors.deepCharcoal,
                          ),
                        ),
                        TextSpan(
                          text: ' $_selectedAmountType',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unit', style: textTheme.bodySmall),
                  const SizedBox(height: 6),
                  SheetPillToggle(
                    options: AmountTypes.types,
                    value: _selectedAmountType,
                    onChanged: _onAmountTypeChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: _amount,
          min: 0.0,
          max: _maxAmount,
          divisions: (_maxAmount * 10).toInt(),
          onChanged: (value) => setState(() => _amount = value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 $_selectedAmountType', style: textTheme.bodySmall),
            Text(
              '${_maxAmount.toInt()} $_selectedAmountType',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
