import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'Models/todo.dart';
import 'screens/home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  
  // تهيئة المناطق الزمنية
  tz.initializeTimeZones();
  final offset = DateTime.now().timeZoneOffset.inHours;
  String localTimeZone;
  if (offset == 2) {
    localTimeZone = "Africa/Tripoli"; // ليبيا
  } else if (offset == 3) {
    localTimeZone = "Europe/Moscow";
  } else {
    localTimeZone = "UTC"; // fallback
  }
  tz.setLocalLocation(tz.getLocation(localTimeZone));


  // تهيئة Hive
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());

  if (Hive.isBoxOpen('todosbox')) {
    await Hive.box<Todo>('todosbox').close();
  }
  final todoBox = await Hive.openBox<Todo>('todosbox');

  // تهيئة الإشعارات
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  

  // إنشاء قناة إشعارات
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'todo_channel_id',
    'ToDo Notifications',
    description: 'Channel for ToDo reminders',
    importance: Importance.max,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // طلب إذن الإشعارات
  await _requestNotificationPermission();

  runApp(MyApp(todoBox: todoBox));
}

Future<void> _requestNotificationPermission() async {
  final status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

class MyApp extends StatelessWidget {
  final Box<Todo> todoBox;

  const MyApp({super.key, required this.todoBox});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(todoBox: todoBox),
    );
  }
}
