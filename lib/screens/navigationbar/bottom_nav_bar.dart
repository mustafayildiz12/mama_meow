import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/models/update_info_modal.dart';
import 'package:mama_meow/screens/get-started/modals/updata_available_modal.dart';
import 'package:mama_meow/screens/navigationbar/home/home_screen.dart';
import 'package:mama_meow/screens/navigationbar/learn/learn_screen.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/my_baby_screen.dart';
import 'package:mama_meow/screens/navigationbar/profile/profile_screen.dart';
import 'package:mama_meow/service/database_service.dart';
import 'package:mama_meow/service/update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AskMeowView(),
    MyBabyScreen(),
    LearnPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    checkAppVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        bottom: Platform.isAndroid ? true : false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
            color: Colors.white,
          ),

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _buildNavItemPng(
                  imagePath: "assets/foot.png",
                  label: 'Ask Meow',
                  index: 0,
                ),
              ),
              Expanded(child: _buildNavItemSvg(label: "My Baby", index: 1)),
              Expanded(
                child: _buildNavItemPng(
                  imagePath: "assets/podcat.png",
                  label: 'Learn',
                  index: 2,
                ),
              ),
              Expanded(
                child: _buildNavItemPng(
                  imagePath: "assets/cat.png",
                  label: 'Profile',
                  index: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItemSvg({required String label, required int index}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.pink.shade600 : Colors.grey.shade600;
    final bgColor = isSelected ? Colors.pink.shade50 : Colors.transparent;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset("assets/baby.svg", width: 36, height: 36),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItemPng({
    required String imagePath,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.pink : Colors.grey.shade600;
    final bgColor = isSelected ? Colors.pink.shade50 : Colors.transparent;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 36, height: 36),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> checkAppVersion() async {
    String newAppVersion = await databaseService.getBasicAppInfo();

    if (applicationVersion != newAppVersion) {
      await getNewUpdateInfo(newAppVersion.replaceAll(".", "x"));
    }
  }

  Future<void> getNewUpdateInfo(String version) async {
    AppUpdateInfo? appUpdateInfo = await UpdateService.instance.fetchVersion(
      version,
    );
    if (appUpdateInfo != null) {
      await showUpdateAppModal(appUpdateInfo);
    }
  }

  Future<void> showUpdateAppModal(AppUpdateInfo updateInfo) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UpdateAvailableModal(
        version: updateInfo.version.replaceAll("x", "."),
        highlights: updateInfo.highlights,
        onCancel: () {
          Navigator.pop(ctx);
        },
        onUpdate: () async {
          Navigator.pop(ctx);
          String storeUrl = "";
          if (GetPlatform.isAndroid) {
            storeUrl = androidUrl;
          } else if (GetPlatform.isIOS) {
            storeUrl = iosUrl;
          }
          await launchUrl(Uri.parse(storeUrl));
        },
      ),
    );
  }
}
