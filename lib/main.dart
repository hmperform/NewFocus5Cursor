import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/coach_provider.dart';
import 'providers/content_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'routes.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CoachProvider()),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        title: 'Focus5',
        theme: appTheme,
        routes: routes,
        onGenerateRoute: generateRoute,
        initialRoute: '/',
        debugShowCheckedModeBanner: false,
      ),
    );
  }
} 