import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/models/activities/medicine_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/medicine_reminders_manager_page.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/analytic_service.dart';

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
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customMedicineController =
      TextEditingController();

  String? _selectedMedicineName;
  String _selectedAmountType = "";
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isCustomMedicine = false;

  @override
  void initState() {
    _selectedAmountType = MedicineAmountTypes.types.first;
    analyticService.screenView('add_medicine_sheet');
    super.initState();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _amountController.dispose();
    _customMedicineController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool _isFormValid() {
    final medicineName = _isCustomMedicine
        ? _customMedicineController.text.trim()
        : _selectedMedicineName;
    final amount = _amountController.text.trim();

    return medicineName != null && medicineName.isNotEmpty && amount.isNotEmpty;
  }

  Future<void> _saveMedicine() async {
    if (!_isFormValid()) return;

    final medicineName = _isCustomMedicine
        ? _customMedicineController.text.trim()
        : _selectedMedicineName!;

    final amount = int.parse(_amountController.text.trim());

    final medicine = MedicineModel(
      startTime: _formatTime(_selectedTime),
      medicineName: medicineName,
      amountType: _selectedAmountType,
      amount: amount,
      createdAt: _formatDateTime(widget.selectedDate, _selectedTime),
    );

    try {
      await medicineService.addMedicine(medicine);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medicine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    final dateStr = DateFormat('EEEE, d MMM').format(widget.selectedDate);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Platform.isAndroid
            ? SafeArea(
                top: false,
                child: sheetBody(scrollController, context, dateStr),
              )
            : sheetBody(scrollController, context, dateStr);
      },
    );
  }

  Container sheetBody(
    ScrollController scrollController,
    BuildContext context,
    String dateStr,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB5E2D6), Color(0xFFA8D5BA)],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: const [BoxShadow(blurRadius: 16, color: Colors.black12)],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const MedicineRemindersManagerPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.alarm_add),
                      ),
                    ],
                  ),
                  Text(
                    dateStr,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Time Selection
                  _SectionCard(
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
                            Icon(
                              Icons.access_time,
                              color: AppColors.kDeepOrange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formatTime(_selectedTime),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Icon(
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
                  _SectionCard(
                    title: 'Medicine',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Select from list'),
                                value: !_isCustomMedicine,
                                onChanged: (value) {
                                  setState(() {
                                    _isCustomMedicine = !(value ?? false);
                                    if (!_isCustomMedicine) {
                                      _customMedicineController.clear();
                                    } else {
                                      _selectedMedicineName = null;
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('Custom'),
                                value: _isCustomMedicine,
                                onChanged: (value) {
                                  setState(() {
                                    _isCustomMedicine = value ?? false;
                                    if (!_isCustomMedicine) {
                                      _customMedicineController.clear();
                                    } else {
                                      _selectedMedicineName = null;
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_isCustomMedicine) ...[
                          TextField(
                            controller: _customMedicineController,
                            decoration: const InputDecoration(
                              labelText: 'Medicine name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.medication),
                            ),
                          ),
                        ] else ...[
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: CommonMedicines.names.map((medicine) {
                                final isSelected =
                                    _selectedMedicineName == medicine;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _MedicineChip(
                                    label: medicine,
                                    icon: _getIconForMedicine(medicine),
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedMedicineName = medicine;
                                      });
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount Section
                  _SectionCard(
                    title: 'Amount',
                    child: Row(
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
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.straighten),
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
                            items: MedicineAmountTypes.types.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedAmountType = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.grey.shade200,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid()
                          ? AppColors.kDeepOrange
                          : Colors.grey,
                    ),
                    onPressed: _isFormValid() ? _saveMedicine : null,
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MedicineChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MedicineChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? AppColors.kOrange : AppColors.kLightOrange,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.kDeepOrange : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? AppColors.kDeepOrange : Colors.black54,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
