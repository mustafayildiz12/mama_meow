// ProfilePage UI generated from provided HTML
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/get-started/modals/update_baby_info_modal.dart';
import 'package:mama_meow/screens/get-started/modals/update_email_password.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';
import 'package:mama_meow/utils/custom_widgets/custom_snackbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isUserPremium = false;

  final ImagePicker _picker = ImagePicker();
  bool _uploadingBabyPic = false;

  @override
  void initState() {
    analyticService.screenView('profile_screen');
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFFEEF2FF),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    checkUserPremium();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildMiaHead(context),
                const SizedBox(height: 8),
                const Text(
                  "Profile",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Text(
                  "Manage your MamaMeow account",
                  style: TextStyle(color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 16),
                _buildUserInfoCard(),
                _buildBabyCard(),
                _buildAboutCard(),
                _buildPremiumCard(),
                settingsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Card settingsCard() {
    final isGuest = authenticationService.getUser() == null;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isGuest)
                  OutlinedButton.icon(
                    onPressed: () async {
                      bool isSuccess = await authenticationService
                          .logoutFromFirebase();

                      if (isSuccess) {
                        context.go(AppRoutes.loginPage);
                      }
                    },
                    icon: Icon(Icons.logout_outlined),
                    label: Text("Logout"),
                  )
                else
                  loginSignUpButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ElevatedButton loginSignUpButton() {
    return ElevatedButton.icon(
      onPressed: () {
        context.go(AppRoutes.loginPage);
      },
      icon: Icon(Icons.login),
      label: Text("Login / Sign Up"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.pink500,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMiaHead(BuildContext context) {
    final pic = (currentMeowUser?.babyPicture ?? "").trim();

    final isGuest = authenticationService.getUser() == null;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: _uploadingBabyPic
          ? null
          : () {
              if (isGuest) {
                context.pushNamed(AppRoutes.loginPage);
              } else {
                _showPickBabyPictureSheet();
              }
            },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFBCFE8), Color(0xFFF9A8D4)],
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            clipBehavior: Clip.antiAlias,
            child: pic.isEmpty
                ? Center(child: Image.asset("assets/cat.png"))
                : CachedNetworkImage(
                    imageUrl: pic,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Center(child: Image.asset("assets/cat.png")),
                    errorWidget: (_, __, ___) =>
                        Center(child: Image.asset("assets/cat.png")),
                  ),
          ),

          // sağ-alt köşeye küçük edit ikonu
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.pink),
            ),
          ),

          if (_uploadingBabyPic)
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final user = authenticationService.getUser();
    final isGuest = user == null;

    return InkWell(
      onTap: () async {
        if (isGuest) {
          context.pushNamed(AppRoutes.loginPage);
          return;
        }
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const UpdateEmailPasswordInfoModal(),
        ).then((v) async {
          if (v == true) {
            await databaseService.updateBaby(currentMeowUser);
            setState(() {});
          }
        });
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E7FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isGuest
                              ? "Guest User"
                              : (currentMeowUser?.userName ?? "User"),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          isGuest
                              ? "Tap to login and save your progress"
                              : (currentMeowUser?.userEmail ?? ""),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.pink500,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBabyCard() {
    return InkWell(
      onTap: () async {
        final user = authenticationService.getUser();
        if (user == null) {
          context.pushNamed(AppRoutes.loginPage);
          return;
        }
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const UpdateBabyInfoModal(),
        ).then((v) async {
          if (v == true) {
            await databaseService.updateBaby(currentMeowUser);
            setState(() {});
          }
        });
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SvgPicture.asset("assets/baby.svg"),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Baby Name: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currentMeowUser?.babyName ?? "?",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "Age Range: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            currentMeowUser?.ageRange ?? "",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppColors.pink500, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return currentMeowUser != null
        ? Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isUserPremium
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(
                              Icons.card_giftcard,
                              size: 20,
                              color: Color(0xFF16A34A),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Premium Features",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _FeatureBullet("Complete Baby Tracking"),
                        _FeatureBullet("Expert Podcast Library"),
                        _FeatureBullet("AI-Powered Asistant"),
                        _FeatureBullet("Priority support"),
                      ],
                    )
                  : Center(
                      child: InkWell(
                        onTap: () async {
                          await bePremium();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.pink.withValues(alpha: 0.6),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                "Be Premium",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          )
        : SizedBox();
  }

  Widget _buildAboutCard() {
    return InkWell(
      onTap: () {},
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 12),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, size: 20, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    "About MamaMeow",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                "MamaMeow was created by parents, for parents. Our AI assistant Mia provides helpful guidance while you navigate the beautiful journey of parenthood.",
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              SizedBox(height: 8),
              Text(
                "Version 1.0.0",
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              Text(
                "© 2024 MamaMeow. Made with 💖 for families.",
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPickBabyPictureSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Set baby photo",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text("Choose from gallery"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAndUploadBabyPicture(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text("Take a photo"),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAndUploadBabyPicture(ImageSource.camera);
                  },
                ),
                if ((currentMeowUser?.babyPicture ?? "").isNotEmpty)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text(
                      "Remove photo",
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _removeBabyPicture();
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadBabyPicture(ImageSource source) async {
    if (currentMeowUser?.uid == null) return;

    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1024,
      );

      if (xfile == null) return;

      setState(() => _uploadingBabyPic = true);

      final url = await _uploadBabyPictureToStorage(
        uid: currentMeowUser!.uid!,
        file: File(xfile.path),
      );

      // modele yaz
      currentMeowUser = currentMeowUser!.copyWith(babyPicture: url);

      // RTDB update
      await databaseService.updateBabyPicture(currentMeowUser);

      setState(() {});
    } catch (e) {
      debugPrint("babyPicture upload error: $e");
      customSnackBar.error("Could not upload photo");
    } finally {
      if (mounted) setState(() => _uploadingBabyPic = false);
    }
  }

  Future<void> _removeBabyPicture() async {
    if (currentMeowUser?.uid == null) return;

    try {
      setState(() => _uploadingBabyPic = true);

      // İstersen storage'daki resmi de sil:
      try {
        final ref = FirebaseStorage.instance.ref().child(
          "users/${currentMeowUser!.uid!}/babyPicture.jpg",
        );
        await ref.delete();
      } catch (_) {
        // dosya yoksa sorun etmeyelim
      }

      currentMeowUser = currentMeowUser!.copyWith(babyPicture: "");
      await databaseService.updateBabyPicture(currentMeowUser);

      setState(() {});
    } catch (e) {
      debugPrint("remove babyPicture error: $e");
      customSnackBar.error("Could not remove photo");
    } finally {
      if (mounted) setState(() => _uploadingBabyPic = false);
    }
  }

  Future<String> _uploadBabyPictureToStorage({
    required String uid,
    required File file,
  }) async {
    final storage = FirebaseStorage.instance;

    // aynı dosyayı overwrite edelim: baby.jpg
    final ref = storage.ref().child("users/$uid/babyPicture.jpg");

    final metadata = SettableMetadata(contentType: "image/jpeg");
    await ref.putFile(file, metadata);

    final url = await ref.getDownloadURL();
    return url;
  }

  Future<void> checkUserPremium() async {
    final user = authenticationService.getUser();
    if (user == null) {
      if (mounted) setState(() => isUserPremium = false);
      return;
    }
    InAppPurchaseService iap = InAppPurchaseService();
    bool isP = await iap.isPremium();
    setState(() {
      isUserPremium = isP;
    });
  }

  Future<void> bePremium() async {
    await context.pushNamed("premiumPaywall").then((v) async {
      if (v != null && v == true) {
        await checkUserPremium();
      }
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Color(0xFFEEF2FF),
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    });
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  const _FeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4ADE80),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
