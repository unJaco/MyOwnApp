import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:my_own_app/Provider/ProfilePictureProvider.dart';
import 'package:my_own_app/Provider/SelectionProvider.dart';
import 'package:my_own_app/Screens/Authentifizierung/Page_ForgotPassword.dart';
import 'package:my_own_app/Screens/HomePage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_own_app/Provider/UserProvider.dart';
import 'package:provider/provider.dart';
import 'Screens/Authentifizierung/Page_Login.dart';
import 'Screens/Authentifizierung/Page_Registration.dart';
import 'Screens/Authentifizierung/Page_VerifyEmail.dart';
import 'Screens/Authentifizierung/Page_Welcome.dart';
import 'Service/AuthenticationService.dart';
import 'firebase_options.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupFlutterNotifications();


  FirebaseMessaging.onMessage.listen((event) {

    Map eventData = event.toMap();

    try{
      print(eventData['notification']);
      Map o = eventData['notification'];
      print(o);
    } catch (e){
      print(e);
    }

    showNotification(event);

  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);



  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await setupFlutterNotifications();
  showNotification(message);
}

late AndroidNotificationChannel channel;

bool isFlutterLocalNotificationsInitialized = false;

late var flutterLocalNotificationsPlugin;

Future<void> setupFlutterNotifications() async {

  if (isFlutterLocalNotificationsInitialized) {
    return;
  }
  channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
    'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  isFlutterLocalNotificationsInitialized = true;
}

Future<void> showNotification(RemoteMessage message) async {

  Map data = message.toMap()['notification'];

  await flutterLocalNotificationsPlugin.show(
    message.hashCode,
    data['title'],
    data['body'],
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'main_channel',
        'Main Channel',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: IOSNotificationDetails(
        sound: 'default.wav',
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthenticationService>(
          create: (_) => AuthenticationService(FirebaseAuth.instance),
        ),
        StreamProvider(
          create: (context) =>
              context.read<AuthenticationService>().idTokenChanges,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SelectionProvider()),
        Provider<ProfilePictureProvider>(create: (_) => ProfilePictureProvider())
      ],
      child: MaterialApp(
        theme: ThemeData(splashColor: Colors.transparent),
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthenticationWrapper(),
          '/welcome': (context) => const WelcomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/registration': (context) => const RegistrationScreen(),
          '/verify': (context) => const VerifyEMailPage(),
          '/forgot password': (context) => const ForgotPasswordPage(),
          '/home': (context) => const HomePage()
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();



    if (firebaseUser == null) {
      return const WelcomeScreen();
    } else {
      if (!firebaseUser.emailVerified) {
        return const VerifyEMailPage();
      }
      return const HomePage();
    }
  }
}
