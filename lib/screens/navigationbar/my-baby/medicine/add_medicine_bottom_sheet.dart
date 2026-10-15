import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/widgets/sheet_widgets.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';

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
        const SnackBar(
          content: Text('Medicine record saved successfully'),
          backgroundColor: Colors.green,
        ),
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
    final theme = Theme.of(context);
    final amountText = _amountController.text.trim();

    return ActivitySheetScaffold(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      radius: 20,
      gradient: const [Color(0xFFB5E2D6), Color(0xFFA8D5BA)],
      attachScrollController: true,
      backLabel: 'Cancel',
      saveColor: AppColors.kDeepOrange,
      onSave: _isFormValid() ? _saveMedicine : null,
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
                  'Add Medicine',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => openReminders(context, 'medicineReminders'),
                icon: const Icon(Icons.alarm_add),
              ),
            ],
          ),
          Text(
            DateFormat('EEEE, d MMM').format(widget.selectedDate),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),

          // Time Selection
          SheetSectionCard(
            title: 'Time',
            child: InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.kLightOrange,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.kDeepOrange),
                    const SizedBox(width: 12),
                    Text(
                      formatHHmm(_selectedTime),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.black54,
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Select from list'),
                        value: !_isCustomMedicine,
                        onChanged: (value) => _setCustom(!(value ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: const Text('Custom'),
                        value: _isCustomMedicine,
                        onChanged: (value) => _setCustom(value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isCustomMedicine)
                  TextField(
                    controller: _customMedicineController,
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Medicine name',
                      border: OutlineInputBorder(),
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
                      border: const OutlineInputBorder(),
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
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
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
