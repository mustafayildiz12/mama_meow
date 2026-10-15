import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/screens/auth/widgets/auth_text_field.dart';

/// Bebek yaş aralığı seçenekleri. Boş değer "seçilmedi" anlamına gelir.
const List<String> babyAgeOptions = [
  '',
  'Newborn (0-3 months)',
  'Infant (3-12 months)',
  'Toddler (1-3 years)',
  'Preschooler (3-5 years)',
  'School age (5+ years)',
  'Expecting mama 🤱',
];

/// Bebek adı + yaş aralığı formu (diyalog olarak). Hem kayıt sonrası
/// ([BabyInfoModal]) hem profilden güncelleme ([UpdateBabyInfoModal]) bunu
/// kullanır.
class BabyInfoForm extends StatefulWidget {
  const BabyInfoForm({
    super.key,
    this.initialName,
    this.initialAgeRange,
    required this.onSubmit,
    this.onBack,
  });

  final String? initialName;
  final String? initialAgeRange;

  /// Devam'a basıldığında (trim'lenmiş ad, seçili yaş aralığı).
  final void Function(String babyName, String? ageRange) onSubmit;

  /// Verilirse "Back" düğmesi gösterilir.
  final VoidCallback? onBack;

  @override
  State<BabyInfoForm> createState() => _BabyInfoFormState();
}

class _BabyInfoFormState extends State<BabyInfoForm> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialName ?? '',
  );

  // Listede olmayan eski bir değer dropdown'ı kırmasın.
  late String? _selectedAge = babyAgeOptions.contains(widget.initialAgeRange)
      ? widget.initialAgeRange
      : null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmit(_nameController.text.trim(), _selectedAge);

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.pink500,
    );
    const fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final continueStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.pink400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

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
              const Text(
                '👶💕 Tell Me About Your Little One',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pink500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's personalize Coo Care Baby Tracker for your family",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _IntroBox(),
              const SizedBox(height: 24),

              const Text("Baby's Name", style: labelStyle),
              const SizedBox(height: 8),
              AuthTextField(
                controller: _nameController,
                maxLength: 30,
                hintText: "Enter your baby's name...",
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                contentPadding: fieldPadding,
              ),
              const Text(
                'You can always change this later in settings 😊',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              const Text("Baby's Age (Optional)", style: labelStyle),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedAge,
                isExpanded: true,
                decoration: AuthTextField.decoration(
                  contentPadding: fieldPadding,
                ),
                hint: const Text('Select age range...'),
                items: [
                  for (final age in babyAgeOptions)
                    DropdownMenuItem(
                      value: age,
                      child: Text(age.isEmpty ? 'Select age range...' : age),
                    ),
                ],
                onChanged: (value) => setState(() => _selectedAge = value),
              ),

              const SizedBox(height: 24),
              const _BenefitsBox(),
              const SizedBox(height: 24),

              if (widget.onBack != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: widget.onBack,
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: continueStyle,
                        onPressed: _submit,
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 120),
                    child: ElevatedButton(
                      style: continueStyle,
                      onPressed: _submit,
                      child: const Text('Continue'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroBox extends StatelessWidget {
  const _IntroBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pink50,
        border: Border.all(color: AppColors.pink200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: AppColors.pink500,
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
    );
  }
}

class _BenefitsBox extends StatelessWidget {
  const _BenefitsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.pink50, AppColors.purple50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pink200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌟 With this info, I can help you with:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.pink500,
            ),
          ),
          SizedBox(height: 12),
          Text('📅 Age-appropriate milestone tracking'),
          Text('🍎 Personalized feeding schedules'),
          Text('😴 Customized sleep routines'),
          Text('🎨 Fun activities for your little one'),
        ],
      ),
    );
  }
}
