import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../screens/profile_dietitian.dart';
import '../screens/video_call_screen.dart';
import 'firebase_options.dart';
import 'models/user.dart';
import 'screens/calendar_client_screen.dart';
import 'screens/calendar_dietitian_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_client_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/messaging_service.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform); // Firebase'i başlat
  await initializeDateFormatting('tr', null); // Türkçe tarih formatını yükle

  // Bildirim servislerini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();

  final messagingService = MessagingService();
  await messagingService.initialize();

  // Bildirim izinlerini kontrol et
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Android için bildirim izinlerini kontrol et
  final androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  if (androidImplementation != null) {
    print('Requesting Android notification permissions...');
    await androidImplementation.requestNotificationsPermission();
    await androidImplementation.requestExactAlarmsPermission();
    print('Android notification permissions requested');
  }

  // iOS için bildirim izinlerini kontrol et
  final iOSImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  if (iOSImplementation != null) {
    print('Requesting iOS notification permissions...');
    await iOSImplementation.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    print('iOS notification permissions requested');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diyetisyen Uygulaması',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppColors.color1,
          secondary: AppColors.color3,
          surface: AppColors.color4,
        ),
        scaffoldBackgroundColor: Color.fromRGBO(255, 255, 255, 1),
        cardColor: AppColors.color4,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashPage(),
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpScreen(),
        '/clientHome': (context) => HomeScreen(userType: UserType.client),
        '/dietitianHome': (context) => HomeScreen(userType: UserType.dietitian),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/videoCall') {
          // Extract the arguments
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: args['channelName'],
              isDietitian: args['isDietitian'],
              uid: args['uid'],
            ),
          );
        }
        return null;
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final UserType userType;
  HomeScreen({required this.userType});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  AppUser? _currentUser;
  List<Widget>? _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  Future<void> _initializePages() async {
    final user = await AuthService().getCurrentUser();
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() {
      _currentUser = user;
      if (widget.userType == UserType.client) {
        _pages = [
          ClientProfileScreen(user: user),
          CalendarScreen(currentUser: user),
        ];
      } else {
        _pages = [
          DietitianProfileScreen(user: user),
          DietitianAppointmentPage(currentUser: user),
        ];
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages == null || _currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _pages![_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Takvim',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
