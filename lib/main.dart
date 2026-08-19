import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/student/student_dashboard_page.dart';
import 'features/teacher/teacher_dashboard_page.dart';
import 'features/wali_kelas/wali_dashboard_page.dart';
import 'features/bk/bk_dashboard_page.dart';
import 'features/piket/piket_dashboard_page.dart';
import 'features/admin/admin_dashboard_page.dart';
import 'core/constants/roles.dart';
import 'core/services/fcm_service.dart';

// Background FCM message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background FCM message: ${message.notification?.title}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const EduTechSMKApp());
}

class EduTechSMKApp extends StatelessWidget {
  const EduTechSMKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'EduTech SMK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.loadCurrentUser();
    if (auth.isLoggedIn) {
      await FcmService().initialize();
      await FcmService().subscribeToRole(auth.user!.role);
    }
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school, size: 72, color: AppTheme.primary),
              SizedBox(height: 16),
              Text('EduTech SMK',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary)),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) return const LoginPage();

    final role = auth.user!.role;
    switch (role) {
      case AppRoles.siswa:
        return const StudentDashboardPage();
      case AppRoles.guruMapel:
        return const TeacherDashboardPage();
      case AppRoles.waliKelas:
        return const WaliDashboardPage();
      case AppRoles.guruBk:
        return const BkDashboardPage();
      case AppRoles.guruPiket:
        return const PiketDashboardPage();
      case AppRoles.admin:
        return const AdminDashboardPage();
      default:
        return const LoginPage();
    }
  }
}
