import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseTopicSubscribeHelper {
  FirebaseTopicSubscribeHelper._();
  factory FirebaseTopicSubscribeHelper() => _instance;
  static final FirebaseTopicSubscribeHelper _instance = FirebaseTopicSubscribeHelper._();



  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      reset();

      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
        onMessage: (message) async {
          print('message: '+message.toString());
          var n = message['notification'];
          if(n != null) {
            cbs.forEach((cb) {cb(n['title'], n['body']);});
          }
        },
        onBackgroundMessage: myBackgroundMessageHandler,// will automatically create a notification
        onLaunch: (Map<String, dynamic> message) async {
          print("onLaunch: $message");
        },
        onResume: (Map<String, dynamic> message) async {
          print("onResume: $message");
        },
      );
      _firebaseMessaging.setAutoInitEnabled(true);

      // For testing purposes print the Firebase Messaging token
      String token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");

      _initialized = true;
    }
  }

  String currentTopic = null;
  Future<void> subscribeTo(String topicName) async {
    await unsubscribeFromCurrent();
    currentTopic = topicName;
    await _firebaseMessaging.subscribeToTopic(topicName);
  }
  Future<void> unsubscribeFromCurrent() async {
    if(isSubscribed())
      await _firebaseMessaging.unsubscribeFromTopic(currentTopic);
    currentTopic=null;
  }
  bool isSubscribed() {
    return currentTopic != null;
  }


  Future<void> reset() async {
    await _firebaseMessaging.deleteInstanceID();
  }

  List<Function(String, String)> cbs = [];
  void addMessageCallback(Function(String, String) cb) {
    cbs.add(cb);
  }
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  var title = message['notification']['title'];
  var body = message['notification']['body'];
  var data = message['data'];
  print("firebase - onMessage");
  print("firebase - oM - raw: $message");
  print("firebase - oM - title: $title");
  print("firebase - oM - body: $body");
  print("firebase - oM - data: $data");
}