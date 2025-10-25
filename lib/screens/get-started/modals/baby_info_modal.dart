import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';

class BabyInfoModal extends StatefulWidget {
  final VoidCallback? onContinue;
  final VoidCallback? onSkip;

  const BabyInfoModal({super.key, this.onContinue, this.onSkip});

  @override
  State<BabyInfoModal> createState() => _BabyInfoModalState();
}

class _BabyInfoModalState extends State<BabyInfoModal> {
  final TextEditingController _nameController = TextEditingController();
  String? selectedAge;

  final List<String> ageOptions = [
    '',
    'Newborn (0-3 months)',
    'Infant (3-12 months)',
    'Toddler (1-3 years)',
    'Preschooler (3-5 years)',
    'School age (5+ years)',
    'Expecting mama 🤱',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 750, maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Center(
                child: Column(
                  children: [
                    Text(
                      '👶💕 Tell Me About Your Little One',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Let\'s personalize MamaMeow for your family',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F5),
                  border: Border.all(color: Color(0xFFFBCFE8)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('🍼', style: TextStyle(fontSize: 30)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "What's your baby's name?",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This helps me give more personalized advice and suggestions tailored to your little one',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Baby's Name Field
              const Text(
                "Baby's Name",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEC4899),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                maxLength: 30,
                onTapOutside: (event) {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                decoration: InputDecoration(
                  hintText: "Enter your baby's name...",
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFBCFE8),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFF472B6),
                      width: 2,
                    ),
                  ),
                ),
              ),
              const Text(
                'You can always change this later in settings 😊',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Baby's Age Dropdown
              const Text(
                "Baby's Age (Optional)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEC4899),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedAge,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFFBCFE8),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFF472B6),
                      width: 2,
                    ),
                  ),
                ),
                hint: const Text('Select age range...'),
                items: ageOptions.map((age) {
                  return DropdownMenuItem(
                    value: age,
                    child: Text(age == '' ? 'Select age range...' : age),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedAge = value),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF1F5), Color(0xFFF3E8FF)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFFBCFE8)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🌟 With this info, I can help you with:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text('📅 Age-appropriate milestone tracking'),
                    Text('🍎 Personalized feeding schedules'),
                    Text('😴 Customized sleep routines'),
                    Text('🎨 Fun activities for your little one'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF472B6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed:
                          widget.onContinue ??
                          () {
                            currentMeowUser = currentMeowUser?.copyWith(
                              babyName: _nameController.text,
                              ageRange: selectedAge,
                            );
                            Navigator.pop(context, true);
                          },
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
