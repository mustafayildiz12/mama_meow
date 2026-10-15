import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/reminders/reminders.dart';

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
        const SnackBar(
          content: Text('Nursing record saved successfully'),
          backgroundColor: Colors.green,
        ),
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

  IconData _getIconForFeedingType(String type) =>
      type.toLowerCase() == 'bottle' ? Icons.local_drink : Icons.child_care;

  IconData _getIconForMilkType(String type) {
    switch (type.toLowerCase()) {
      case 'breast milk':
        return Icons.child_care;
      case 'formula':
        return Icons.science;
      case 'tube feeding':
        return Icons.medical_services;
      case 'cow milk':
      case 'goat milk':
        return Icons.pets;
      case 'soy milk':
        return Icons.eco;
      default:
        return Icons.local_drink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActivitySheetScaffold(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      radius: 20,
      gradient: const [Color(0xFFFF9AA2), Color(0xFFFFB3BA)],
      attachScrollController: true,
      backLabel: 'Cancel',
      saveColor: Colors.teal,
      onSave: _isFormValid() ? _saveNursing : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Add Nursing',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openReminders,
                icon: Icon(
                  Icons.alarm_add,
                  color: _hasReminder ? Colors.teal : null,
                ),
              ),
            ],
          ),
          Text(
            DateFormat('EEEE, d MMM').format(DateTime.now()),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          ChipPickerSection<String>(
            title: "Feeding Type",
            items: FeedingTypes.types,
            value: _selectedFeedingType,
            style: ChipTileStyle.teal,
            onChanged: _onFeedingTypeChanged,
            iconBuilder: _getIconForFeedingType,
          ),
          const SizedBox(height: 16),

          if (_selectedFeedingType == 'Nursing') ...[
            ChipPickerSection<String>(
              title: "Side",
              items: NursingSides.sides,
              value: _selectedSide,
              style: ChipTileStyle.teal,
              onChanged: (v) => setState(() => _selectedSide = v),
              iconBuilder: _getIconForSide,
            ),
            const SizedBox(height: 16),
          ],

          if (_isBottle) ...[
            ChipPickerSection<String>(
              title: "Milk Type",
              items: MilkTypes.types,
              value: _selectedMilkType,
              style: ChipTileStyle.teal,
              onChanged: (v) => setState(() => _selectedMilkType = v),
              iconBuilder: _getIconForMilkType,
            ),
            const SizedBox(height: 16),
            SheetSectionCard(title: 'Amount', child: _amountPicker()),
            const SizedBox(height: 16),
          ],

          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        Text(formatHHmm(_selectedTime)),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down),
                      ],
                    ),
                  ),
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
                    border: OutlineInputBorder(),
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedAmountType,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final type in AmountTypes.types)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedAmountType = value;
                    _amount = 0.0; // birim değişince miktar sıfırlanır
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${_amount.toStringAsFixed(1)} $_selectedAmountType',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Slider(
          value: _amount,
          min: 0.0,
          max: _maxAmount,
          divisions: (_maxAmount * 10).toInt(),
          activeColor: Colors.teal,
          onChanged: (value) => setState(() => _amount = value),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0 $_selectedAmountType'),
            Text('${_maxAmount.toInt()} $_selectedAmountType'),
          ],
        ),
      ],
    );
  }
}
