import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- import this
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:staysafe/view/screens/registration_screens/splash_screen.dart';
import 'Controller/chat_controller.dart';
import 'Controller/report_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // ensure bindings are initialized

  // Hide the status bar completely (battery, time, icons)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => ChatController()), // <-- added
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: child,
        );
      },
      child: const SplashScreen(),
    );
  }
}
