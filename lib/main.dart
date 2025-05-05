import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello/settings/theme_notifier.dart';
import 'package:hello/login/info.dart';
import 'package:hello/login/login.dart';
import 'package:hello/login/register.dart';
import 'package:hello/login/forgot_password.dart';
import 'package:hello/seller/home_page.dart';
import 'package:hello/user/home_page.dart';
import 'package:hello/settings/settings.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDark = prefs.getBool('isDarkMode') ?? false;


  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(isDark),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Cloth oclock',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/info',
          routes: {
            '/info': (context) => const InfoPage(),
            '/login': (context) => const MyLogin(),
            '/forgot_password': (context) => const ForgotPassword(),
            '/register': (context) => const MyRegister(),
            '/homepage': (context) => UserHomePage(),
            '/seller_homepage': (context) => SellerHomePage(),
            '/settings': (context) => SettingsScreen(
            ),
          },
        );
      },
    );
  }
}