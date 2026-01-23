import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mama_meow/models/activities/nursing_model.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/reminder_manager_page.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/service/prefs/nursing_prefs.dart';

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

  NursingReminderSettings? _reminder; // mevcut ayar (ikon rengi vs için)

  @override
  void initState() {
    analyticService.screenView('add_nursing_sheet');
    super.initState();
    ReminderPrefs.load().then((s) {
      if (mounted) setState(() => _reminder = s);
    });
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  bool _isFormValid() {
    if (_selectedFeedingType != null && _selectedFeedingType == "Nursing") {
      return _selectedSide != null;
    } else if (_selectedFeedingType != null &&
        _selectedFeedingType == "Bottle") {
      return _selectedMilkType != null && _amount > 0;
    } else {
      return false;
    }
  }

  double get _maxAmount {
    return _selectedAmountType == 'oz' ? 12.0 : 350.0;
  }

  Future<void> _saveNursing() async {
    if (!_isFormValid()) return;

    final nursing = NursingModel(
      side: _selectedSide ?? "",
      startTime: _formatTime(_selectedTime),
      duration: int.tryParse(_durationController.text) ?? 0,
      feedingType: _selectedFeedingType!.toLowerCase(),
      milkType: _selectedFeedingType == 'Bottle' ? _selectedMilkType : null,
      amountType: _selectedAmountType,
      amount: _amount,
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await nursingService.addNursing(nursing);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nursing record saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving nursing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconForSide(String side) {
    switch (side.toLowerCase()) {
      case 'left':
        return Icons.keyboard_arrow_left;
      case 'right':
        return Icons.keyboard_arrow_right;
      case 'center':
        return Icons.center_focus_strong;
      default:
        return Icons.center_focus_strong;
    }
  }

  IconData _getIconForFeedingType(String type) {
    switch (type.toLowerCase()) {
      case 'nursing':
        return Icons.child_care;
      case 'bottle':
        return Icons.local_drink;
      default:
        return Icons.child_care;
    }
  }

  IconData _getIconForMilkType(String type) {
    switch (type.toLowerCase()) {
      case 'breast milk':
        return Icons.child_care;
      case 'formula':
        return Icons.science;
      case 'tube feeding':
        return Icons.medical_services;
      case 'cow milk':
        return Icons.pets;
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
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Platform.isAndroid
            ? SafeArea(top: false, child: sheetBody(scrollController, context))
            : sheetBody(scrollController, context);
      },
    );
  }

  Container sheetBody(ScrollController scrollController, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF9AA2), Color(0xFFFFB3BA)],
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
                          'Add Nursing',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                           await AlarmPolicy.instance.ensure();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const NursingRemindersManagerPage(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.alarm_add,
                          color: (_reminder?.enabled ?? false)
                              ? Colors.teal
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    DateFormat('EEEE, d MMM').format(DateTime.now()),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),

                  // Feeding Type Selection
                  _ChipPickerSection(
                    title: "Feeding Type",
                    items: FeedingTypes.types,
                    value: _selectedFeedingType,
                    onChanged: (v) {
                      setState(() {
                        _selectedFeedingType = v;
                        if (v == 'Nursing') {
                          _selectedMilkType = null;
                        }
                      });
                    },
                    iconBuilder: _getIconForFeedingType,
                  ),
                  const SizedBox(height: 16),

                  // Side Selection
                  if (_selectedFeedingType == "Nursing") ...[
                    _ChipPickerSection(
                      title: "Side",
                      items: NursingSides.sides,
                      value: _selectedSide,
                      onChanged: (v) => setState(() => _selectedSide = v),
                      iconBuilder: _getIconForSide,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Milk Type Selection (only for bottle)
                  if (_selectedFeedingType == 'Bottle') ...[
                    _ChipPickerSection(
                      title: "Milk Type",
                      items: MilkTypes.types,
                      value: _selectedMilkType,
                      onChanged: (v) => setState(() => _selectedMilkType = v),
                      iconBuilder: _getIconForMilkType,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Time and Duration

                  // Amount Section
                  if (_selectedFeedingType == 'Bottle') ...[
                    _SectionCard(
                      title: 'Amount',
                      child: Column(
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
                                  items: AmountTypes.types.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedAmountType = value;
                                        _amount =
                                            0.0; // Reset amount when unit changes
                                      });
                                    }
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
                            onChanged: (value) {
                              setState(() {
                                _amount = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0 $_selectedAmountType'),
                              Text(
                                '${_maxAmount.toInt()} $_selectedAmountType',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
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
                                Text(_formatTime(_selectedTime)),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                          ? Colors.teal
                          : Colors.grey,
                    ),
                    onPressed: _isFormValid() ? _saveNursing : null,
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

class _ChipPickerSection extends StatelessWidget {
  final String title;
  final List<String> items;
  final String? value;
  final ValueChanged<String> onChanged;
  final IconData Function(String) iconBuilder;

  const _ChipPickerSection({
    required this.title,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.iconBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ChipTile(
                    label: item,
                    icon: iconBuilder(item),
                    selected: item == value,
                    onTap: () => onChanged(item),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChipTile({
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
          color: selected ? Colors.teal.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.teal : Colors.black12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? Colors.teal : Colors.black54,
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
