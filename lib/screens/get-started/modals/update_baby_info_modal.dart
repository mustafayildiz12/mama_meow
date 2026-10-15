import 'package:flutter/material.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/screens/get-started/widgets/baby_info_form.dart';

/// Profilden bebek bilgisini güncelleme modalı. Onaylanırsa `true` ile
/// kapanır ve [currentMeowUser] güncellenir (kaydetme çağırana aittir).
class UpdateBabyInfoModal extends StatelessWidget {
  const UpdateBabyInfoModal({super.key});

  @override
  Widget build(BuildContext context) {
    return BabyInfoForm(
      initialName: currentMeowUser?.babyName,
      initialAgeRange: currentMeowUser?.ageRange,
      onBack: () => Navigator.pop(context),
      onSubmit: (babyName, ageRange) {
        currentMeowUser = currentMeowUser?.copyWith(
          babyName: babyName,
          ageRange: ageRange,
        );
        Navigator.pop(context, true);
      },
    );
  }
}
