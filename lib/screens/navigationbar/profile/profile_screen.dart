// ProfilePage UI generated from provided HTML
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mama_meow/constants/app_constants.dart';
import 'package:mama_meow/constants/app_routes.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/service/database_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                //   _buildUsageCard(),
                //   _buildPremiumCard(),
                _buildAboutCard(),

                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
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
                            TextButton(
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
                              child: Text("Logout"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog.adaptive(
                                      title: Text("Delete Account?"),
                                      content: Text(
                                        "Are you sure you want to delete your account? All your data will be deleted along with your account. Do you still want to proceed?",
                                      ),
                                      actions: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text("Back"),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: Text("Delete"),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ).then((value) async {
                                  if (value == true) {
                                    bool isSuccess = await databaseService
                                        .deleteAccount(context);
                                    if (isSuccess) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.loginPage,
                                        (_) => false,
                                      );
                                    }
                                  }
                                });
                              },
                              child: Text("Delete Account"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      child: const Center(child: Text("😺", style: TextStyle(fontSize: 36))),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
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
              ],
            ),
            const SizedBox(height: 12),
            /*
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.emoji_events, size: 20, color: Color(0xFF9333EA)),
                  SizedBox(width: 8),
                  Text(
                    "Monthly Plan",
                    style: TextStyle(
                      color: Color(0xFF6B21A8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildBabyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
                          Text(
                            "${currentMeowUser?.babyName ?? "?"}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
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
                          Text(
                            "${currentMeowUser?.ageRange ?? ""}",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.calendar_today, size: 20, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  "Today's Usage",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Column(
                  children: [
                    Text(
                      "1",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Questions Asked",
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "∞",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Remaining",
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Icon(Icons.card_giftcard, size: 20, color: Color(0xFF16A34A)),
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
            _FeatureBullet("Unlimited questions"),
            _FeatureBullet("No ads"),
            _FeatureBullet("Priority support"),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
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
    );
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
