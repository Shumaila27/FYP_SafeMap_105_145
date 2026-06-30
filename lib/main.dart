import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:staysafe/view/screens/auth_checker_screen.dart';
import 'package:staysafe/view/screens/dashboard.dart';
import 'package:staysafe/view/screens/community_vote_screen.dart'; // ✅ NEW
import 'Controller/chat_controller.dart';
import 'Controller/auth_provider.dart';
import 'Controller/map_controller.dart';
import 'Controller/theme_controller.dart';
import 'Controller/report_controller.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// ✅ NEW — global navigator key so notification taps can navigate
// without needing a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

// Central place that reacts to a notification's "screen" field.
// Handles: map (Safe Walk / Emergency), vote (Community Report Voting)
void _handleNotificationNavigation(RemoteMessage message) {
  final screen = message.data['screen'];

  // ── Safe Walk / SOS / Emergency ────────────────────────────────────────
  if (screen == 'map') {
    // Refresh guardian's tracked walk immediately so the marker/banner
    // appears even if MapScreen is already mounted and won't re-run init().
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      ctx.read<MapController>().refreshTrackedWalk();
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashBoardScreen()),
      (route) => false,
    );
    return;
  }

  // ── Community Vote ──────────────────────────────────────────────────────
  if (screen == 'vote') {
    final reportId     = message.data['report_id']     as String?;
    final categoryName = message.data['category_name'] as String? ?? 'Incident';
    final description  = message.data['description']  as String? ?? '';

    // Guard: only navigate if we have a valid report ID
    if (reportId == null || reportId.isEmpty) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CommunityVoteScreen(
          reportId:     reportId,
          categoryName: categoryName,
          description:  description,
        ),
      ),
    );
    return;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await dotenv.load(fileName: ".env"); // keep first — others depend on it

  // ✅ Run Supabase + Firebase concurrently instead of one-by-one
  await Future.wait([
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ),
    Firebase.initializeApp(),
  ]);

  // Register background handler (no await needed)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Run permission + initial message fetch concurrently
  final results = await Future.wait([
    FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    ),
    FirebaseMessaging.instance.getInitialMessage(),
  ]);

  // ✅ App opened from a TERMINATED state by tapping a notification
  final initialMessage = results[1] as RemoteMessage?;
  if (initialMessage != null) {
    // Navigation here happens after runApp, so we defer it slightly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation(initialMessage);
    });
  }

  // ✅ NEW — App was in BACKGROUND and brought to foreground via notification tap
  FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationNavigation);

  // ✅ NEW — App is in FOREGROUND and receives a notification
  FirebaseMessaging.onMessage.listen((message) {
    _handleNotificationNavigation(message);
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => ChatController()..init()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => MapController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        const seedColor = Color(0xFF14B8A6);
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [routeObserver],
          themeMode: themeController.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            cardColor: Colors.white,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 1,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return seedColor;
                return const Color(0xFF9CA3AF);
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return seedColor.withValues(alpha: 0.35);
                }
                return const Color(0xFFE5E7EB);
              }),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0B1220),
            cardColor: const Color(0xFF111827),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 1,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF2DD4BF);
                }
                return const Color(0xFF94A3B8);
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF2DD4BF).withValues(alpha: 0.35);
                }
                return const Color(0xFF334155);
              }),
            ),
          ),
          home: const AuthCheckerScreen(),
        );
      },
    );
  }
}