import Flutter
import UIKit
import UserNotifications
// FlutterLocalNotificationsPlugin.setPluginRegistrantCallback için gerekli.
import flutter_local_notifications

// UIScene yaşam döngüsü: pencere/sahne olaylarını Info.plist'teki
// FlutterSceneDelegate yönetir; eklentiler örtük (implicit) motor
// oluşturulunca kaydedilir.
@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Uygulama ön plandayken de yerel bildirimler gösterilsin.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Bildirime arka planda yanıt verildiğinde açılan ayrı motorda da
    // eklentiler kayıtlı olsun.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
  }
}
