import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:staysafe/view/screens/auth_checker_screen.dart';
import 'Controller/chat_controller.dart';
import 'Controller/auth_provider.dart';
import 'Controller/theme_controller.dart';
import 'Controller/report_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  //Loading of .env file
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (context, child) {
        return Consumer<ThemeController>(
          builder: (context, themeController, _) {
            const seedColor = Color(0xFF14B8A6);
            return MaterialApp(
              debugShowCheckedModeBanner: false,
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
                    if (states.contains(WidgetState.selected)) {
                      return seedColor;
                    }
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
              home: child,
            );
          },
        );
      },
      child: const AuthCheckerScreen(),
    );
  }
}
