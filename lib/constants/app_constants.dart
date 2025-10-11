import 'package:get_storage/get_storage.dart';
import 'package:mama_meow/models/meow_user_model.dart';

final GetStorage localStorage = GetStorage("local");
final GetStorage infoStorage = GetStorage("info");

String applicationVersion = "";

String androidUrl = "";
String iosUrl = "";

String androidVersion = "";
String iosVersion = "";

MeowUserModel? currentMeowUser;

bool isTrial = false;
