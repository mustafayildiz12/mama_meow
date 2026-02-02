import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/diaper/add_diaper_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/journal/journal_screen.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/medicine/add_medicine_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/nursing/add_nursing_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/pumping/add_pumping_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/sleep/add_sleep_bottom_sheet.dart';
import 'package:mama_meow/screens/navigationbar/my-baby/solid/add_solid_bottom_sheet.dart';
import 'package:mama_meow/service/activities/diaper_service.dart';
import 'package:mama_meow/service/activities/medicine_service.dart';
import 'package:mama_meow/service/activities/nursing_service.dart';
import 'package:mama_meow/service/activities/pumping_service.dart';
import 'package:mama_meow/service/activities/sleep_service.dart';
import 'package:mama_meow/service/activities/solid_service.dart';
import 'package:mama_meow/service/analytic_service.dart';
import 'package:mama_meow/service/permissions/alarm_policy.dart';
import 'package:mama_meow/service/authentication_service.dart';
import 'package:mama_meow/constants/app_routes.dart';

class MyBabyScreen extends StatefulWidget {
  const MyBabyScreen({super.key});

  @override
  State<MyBabyScreen> createState() => _MyBabyScreenState();
}

class _MyBabyScreenState extends State<MyBabyScreen>
    with WidgetsBindingObserver {
  late final Stream<int> _solidCount$;
  late final Stream<int> _sleepCount$;
  late final Stream<int> _diaperCount$;
  late final Stream<int> _pumpingCount$;
  late final Stream<int> _medicineCount$;
  late final Stream<int> _nursingCount$;

  @override
  void initState() {
    analyticService.screenView('my_baby_screen');
    // Eğer service zaten broadcast veriyorsa .asBroadcastStream() şart değil,
    // emin değilsen ekle (zararı yok):
    updateTopUi();
    _solidCount$ = solidService.todaySolidCountStream().asBroadcastStream();
    _sleepCount$ = sleepService.todaySleepCountStream().asBroadcastStream();
    _diaperCount$ = diaperService.todayDiaperCountStream().asBroadcastStream();
    _pumpingCount$ = pumpingService
        .todayPumpingCountStream()
        .asBroadcastStream();
    _medicineCount$ = medicineService
        .todayMedicineCountStream()
        .asBroadcastStream();
    _nursingCount$ = nursingService
        .todayNursingCountStream()
        .asBroadcastStream();
    WidgetsBinding.instance.addObserver(this);
    AlarmPolicy.instance.refresh(); // sessiz kontrol
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AlarmPolicy.instance.refresh();
    }
  }

  void updateTopUi() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Theme.of(context).scaffoldBackgroundColor,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    });
  }

  Future<void> _checkAuthAndProceed(VoidCallback action) async {
    final user = authenticationService.getUser();
    if (user == null) {
      context.pushNamed(AppRoutes.loginPage);
    } else {
      action();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                SizedBox(height: 12),
                SvgPicture.asset("assets/baby.svg", width: 64, height: 64),
                SizedBox(height: 8),
                Text(
                  "My Baby 👶",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "I may be small, but my stories are big! Don't miss a meowment! 🐾✨",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
          StreamBuilder(
            stream: _nursingCount$,
            builder: (context, snapshot) {
              int nursingCount = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '🍼',
                title: 'Nursing',
                subtitle: 'Today: $nursingCount times',
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9AA2), Color(0xFFFFB3BA)],
                ),
                textColor: Colors.green.shade700,
                bgColor: Colors.green.shade50,
                onReportPressed: () {
                  context.pushNamed('nursingReport');
                },
                onPlusPressed: () {
                  _checkAuthAndProceed(() async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => const AddNursingBottomSheet(),
                    );
                  });
                },
              );
            },
          ),

          const SizedBox(height: 16),
          StreamBuilder(
            stream: _solidCount$,
            builder: (context, snapshot) {
              int solidTime = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '🍛',
                title: 'Solid',
                subtitle: 'Today: $solidTime times',
                gradient: LinearGradient(
                  colors: [Color(0xFFA8E6CF), Color(0xFF88D8C0)],
                ),
                textColor: Colors.orange.shade700,
                bgColor: Colors.orange.shade50,
                onReportPressed: () {
                  context.pushNamed('solidReport');
                },
                onPlusPressed: () {
                  _checkAuthAndProceed(() async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => const AddSolidBottomSheet(),
                    );
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: _sleepCount$,
            builder: (context, snapshot) {
              int sleepTime = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '😴',
                title: 'Sleep',
                subtitle: 'Today: $sleepTime times',
                gradient: LinearGradient(
                  colors: [Colors.blue.shade200, Colors.purple.shade200],
                ),
                textColor: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
                onReportPressed: () {
                  context.pushNamed('sleepReport');
                },
                onPlusPressed: () {
                  _checkAuthAndProceed(() async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder:
                          (_) => SleepExtendedMultiSliderBottomSheet(
                            initialStartEnds: [12 * 60, 15 * 60],
                            sleepDate: DateTime.now(),
                          ),
                    );
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: _diaperCount$,
            builder: (context, snapshot) {
              int diaperTime = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '👶',
                title: 'Diaper',
                subtitle: 'Today: $diaperTime times',
                gradient: LinearGradient(
                  colors: [Colors.green.shade200, Colors.tealAccent.shade200],
                ),
                textColor: Colors.green.shade700,
                bgColor: Colors.green.shade50,
                onReportPressed: () {
                  context.pushNamed('diaperReport');
                },
                onPlusPressed: () {
                  _checkAuthAndProceed(() async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => const AddDiaperBottomSheet(),
                    );
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: _pumpingCount$,
            builder: (context, snapshot) {
              int pumpingTime = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '👩‍🍼',
                title: 'Pumping',
                subtitle: 'Today: $pumpingTime times',
                gradient: LinearGradient(
                  colors: [Color(0xFFFFCAB0), Color(0xFFFFD3A5)],
                ),
                textColor: Colors.pink.shade700,
                bgColor: Colors.pink.shade50,
                onReportPressed: () {
                  context.pushNamed('pumpingReport');
                },
                onPlusPressed: () {
                  _checkAuthAndProceed(() async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => const AddPumpingBottomSheet(),
                    );
                  });
                },
              );
            },
          ),

          const SizedBox(height: 16),
          StreamBuilder(
            stream: _medicineCount$,
            builder: (context, snapshot) {
              int medicineCount = snapshot.hasData ? snapshot.data! : 0;
              return _babyCard(
                emoji: '💊',
                title: 'Medicine',
                subtitle: 'Today: $medicineCount times',
                gradient: LinearGradient(
                  colors: [Color(0xFFB5E2D6), Color(0xFFA8D5BA)],
                ),
                textColor: Colors.red.shade700,
                bgColor: Colors.red.shade50,
                onReportPressed: () {
                  context.pushNamed('medicineReport');
                },
                onPlusPressed: () {
                  _checkAuthAndProceed(() async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder:
                          (context) => AddMedicineBottomSheet(
                            selectedDate: DateTime.now(),
                          ),
                    );
                  });
                },
              );
            },
          ),

          const SizedBox(height: 16),

          _babyCardJournal(
            emoji: '📔',
            title: 'Journal',

            gradient: LinearGradient(
              colors: [Colors.purple.shade100, Colors.indigo.shade200],
            ),
            textColor: Colors.purple.shade600,
            bgColor: Colors.purple.shade50,
            onReportPressed: () async {
              _checkAuthAndProceed(() async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => const JournalDiaryPage(),
                );
              });
            },
          ),

          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.yellow.shade100, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber, width: 2),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      color: Colors.amber,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Tips for Today',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amberAccent, width: 2),
                  ),
                  child: const Text(
                    '💡 Tip of the day: Babies typically need 8-12 feedings per day. Watch for hunger cues like rooting or sucking motions!',
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _babyCard({
    required String emoji,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required Color textColor,
    required Color bgColor,
    required void Function() onPlusPressed,
    void Function()? onReportPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        onReportPressed!();
                      },
                      icon: Icon(LucideIcons.barChart3, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () {
                        onPlusPressed();
                      },
                      icon: Icon(LucideIcons.plus, color: textColor, size: 28),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _babyCardJournal({
    required String emoji,
    required String title,

    required LinearGradient gradient,
    required Color textColor,
    required Color bgColor,

    void Function()? onReportPressed,
  }) {
    return InkWell(
      onTap: onReportPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
