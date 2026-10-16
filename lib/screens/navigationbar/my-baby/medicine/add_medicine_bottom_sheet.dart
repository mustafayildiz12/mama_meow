import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_theme.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/utils/custom_widgets/berry_ui.dart';

/// Medicine amount types
class MedicineAmountTypes {
  static const List<String> types = ['oz', 'ml', 'tea spoon', 'drops'];
}

/// Common medicine names
class CommonMedicines {
  static const List<String> names = [
    'Vitamin',
    'B12',
    'Vitamin C',
    'Iron',
    'Cough syrup',
  ];
}

class AddMedicineBottomSheet extends StatefulWidget {
  final DateTime selectedDate;

  const AddMedicineBottomSheet({super.key, required this.selectedDate});

  @override
  State<AddMedicineBottomSheet> createState() => _AddMedicineBottomSheetState();
}

class _AddMedicineBottomSheetState extends State<AddMedicineBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customMedicineController =
      TextEditingController();

  String? _selectedMedicineName;
  String _selectedAmountType = MedicineAmountTypes.types.first;
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isCustomMedicine = false;

  @override
  void initState() {
    super.initState();
    analyticService.screenView('add_medicine_sheet');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customMedicineController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime date, TimeOfDay time) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  Future<void> _selectTime() async {
    final picked = await pick24hTime(context, _selectedTime);
    if (picked != null && mounted) setState(() => _selectedTime = picked);
  }

  String? get _medicineName {
    final name = _isCustomMedicine
        ? _customMedicineController.text.trim()
        : _selectedMedicineName;
    return (name == null || name.isEmpty) ? null : name;
  }

  /// "2.5" ve "0,5" kabul edilir; 0 veya geçersizse null.
  num? get _amount {
    final v = num.tryParse(_amountController.text.trim().replaceAll(',', '.'));
    return (v == null || v <= 0) ? null : v;
  }

  bool _isFormValid() => _medicineName != null && _amount != null;

  void _setCustom(bool custom) {
    setState(() {
      _isCustomMedicine = custom;
      if (custom) {
        _selectedMedicineName = null;
      } else {
        _customMedicineController.clear();
      }
    });
  }

  Future<void> _saveMedicine() async {
    final name = _medicineName;
    final amount = _amount;
    if (name == null || amount == null) return;
    if (authenticationService.getUser() == null) {
      context.pushNamed("login");
      return;
    }

    final medicine = MedicineModel(
      startTime: formatHHmm(_selectedTime),
      medicineName: name,
      amountType: _selectedAmountType,
      amount: amount,
      createdAt: _formatDateTime(widget.selectedDate, _selectedTime),
    );

    try {
      await medicineService.addMedicine(medicine);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Medicine record saved successfully')),
      );
    } catch (e) {
      debugPrint('addMedicine failed: $e');
      if (!mounted) return;
      showSaveError(context);
    }
  }

  IconData _getIconForMedicine(String medicine) {
    switch (medicine.toLowerCase()) {
      case 'vitamin':
        return Icons.wb_sunny;
      case 'b12':
        return Icons.psychology;
      case 'vitamin c':
        return Icons.local_pharmacy;
      case 'iron':
        return Icons.fitness_center;
      case 'cough syrup':
        return Icons.air;
      default:
        return Icons.medication;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = _amountController.text.trim();

    return ActivitySheetScaffold(
      kind: ActivityKind.medicine,
      title: 'Add Medicine',
      subtitle: DateFormat('EEEE, d MMM').format(widget.selectedDate),
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      attachScrollController: true,
      onSave: _isFormValid() ? _saveMedicine : null,
      // Hatırlatıcı butonu başlıkta, kapatma butonunun yanında durur.
      actions: [
        IconButton(
          tooltip: 'Reminders',
          onPressed: () => openReminders(context, 'medicineReminders'),
          style: IconButton.styleFrom(backgroundColor: AppColors.pinkTint),
          icon: const Icon(Icons.alarm_add, color: AppColors.deepCharcoal),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Selection
          SheetSectionCard(
            title: 'Time',
            child: InkWell(
              onTap: _selectTime,
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              child: InputDecorator(
                decoration: const InputDecoration(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 20,
                      color: AppColors.activeBerry,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatHHmm(_selectedTime),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.charcoalSoft,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Medicine Selection
          SheetSectionCard(
            title: 'Medicine',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Listeden seç / özel ad: iki seçenekli hap geçiş.
                _PillToggle(
                  options: const ['Select from list', 'Custom'],
                  value: _isCustomMedicine ? 'Custom' : 'Select from list',
                  onChanged: (option) => _setCustom(option == 'Custom'),
                ),
                const SizedBox(height: 16),
                if (_isCustomMedicine)
                  TextField(
                    controller: _customMedicineController,
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      prefixIcon: Icon(Icons.medication),
                    ),
                  )
                else
                  ChipPickerSection<String>(
                    items: CommonMedicines.names,
                    value: _selectedMedicineName,
                    style: ChipTileStyle.orangeSmall,
                    iconBuilder: _getIconForMedicine,
                    onChanged: (medicine) =>
                        setState(() => _selectedMedicineName = medicine),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount Section
          SheetSectionCard(
            title: 'Amount',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: TextField(
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: const Icon(Icons.straighten),
                      errorText: amountText.isNotEmpty && _amount == null
                          ? 'Enter an amount greater than 0'
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 5,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAmountType,
                    dropdownColor: AppColors.cottonWhite,
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    iconEnabledColor: AppColors.charcoalSoft,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      for (final type in MedicineAmountTypes.types)
                        DropdownMenuItem(
                          value: type,
                          child: Text(type, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAmountType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pembe hap zemin üzerinde berry seçili dilimli iki seçenekli geçiş.
class _PillToggle extends StatelessWidget {
  const _PillToggle({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _PillSegment(
                label: option,
                selected: option == value,
                onTap: () => onChanged(option),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected ? AppColors.activeBerry : Colors.transparent,
          borderRadius: radius,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected
                      ? AppColors.cottonWhite
                      : AppColors.deepCharcoal,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
