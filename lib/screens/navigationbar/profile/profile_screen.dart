// ProfilePage UI generated from provided HTML
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_meow/constants/app_colors.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/screens/get-started/modals/update_baby_info_modal.dart';
import 'package:mama_meow/screens/get-started/modals/update_email_password.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/in_app_purchase_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isUserPremium = false;

  @override
  void initState() {
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
                OutlinedButton.icon(
                  onPressed: () async {
                    bool isSuccess = await authenticationService
                        .logoutFromFirebase();

                    if (isSuccess) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.loginPage,
                        (_) => false,
                      );
                    }
                  },
                  icon: Icon(Icons.logout_outlined),
                  label: Text("Logout"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiaHead(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFBCFE8), Color(0xFFF9A8D4)],
        ),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const Center(child: Text("😺", style: TextStyle(fontSize: 48))),
    );
  }

  Widget _buildUserInfoCard() {
    return InkWell(
      onTap: () async {
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
                          currentMeowUser?.userName ?? "Guest",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          currentMeowUser?.userEmail ?? "",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: AppColors.pink500,size: 16,),
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
                              fontSize: 12
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
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }

  Widget _buildAboutCard() {
    return InkWell(
      onTap: () {
        //  Navigator.pushNamed(context, AppRoutes.adminUpdate);
      },
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

  Future<void> checkUserPremium() async {
    InAppPurchaseService iap = InAppPurchaseService();
    bool isP = await iap.isPremium();
    setState(() {
      isUserPremium = isP;
    });
  }

  Future<void> bePremium() async {
    await Navigator.pushNamed(context, AppRoutes.premiumPaywall).then((
      v,
    ) async {
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
