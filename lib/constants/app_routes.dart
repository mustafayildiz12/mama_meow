class AppRoutes {
  static String initialRoute = getStartedPage;
  static String getStartedPage = "/getStarted";

  static String loginPage = "/loginPage";
  static String registerPage = "/registerPage";

  static String navigationBarPage = "/navigationBar";

  static String forgotPasswordPage = "/forgotPassword";
  static String uploadPodcastPage = "/uploadPodcast";
  static String premiumPaywall = "/premiumPaywall";

  static String adminUpdate = "/adminUpdate";

  // Auth sonrası (Shell + Tabs)
  static const String shell = '/app';

  static const String askMeow = '/askMeow';
  static const String myBaby = '/myBaby';

  static const String nursingReport = 'nursing-report';
  static const String solidReport = 'solid-report';
  static const String sleepReport = 'sleep-report';
  static const String diaperReport = 'diaper-report';
  static const String pumpingReport = 'pumping-report';
  static const String medicineReport = 'medicine-report';

  static const String diaperReminders = 'diaper-reminders';
  static const String medicineReminders = 'medicine-reminders';
  static const String nursingReminders = 'nursing-reminders';
  static const String pumpingReminders = 'pumping-reminders';
  static const String sleepReminders = 'sleep-reminders';
  static const String solidReminders = 'solid-reminders';

  static const String learn = '/learn';
  static const String profile = '/profile';
}
