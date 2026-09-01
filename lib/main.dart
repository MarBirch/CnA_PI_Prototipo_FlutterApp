import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:prototipo1/app_theme.dart';
import 'package:prototipo1/auth_provider.dart';
import 'package:prototipo1/cadastro.dart';
import 'package:prototipo1/navigation.dart';
import 'package:prototipo1/login.dart';
import 'package:prototipo1/main_home_screen.dart';
import 'package:prototipo1/splashscreen.dart';
import 'package:prototipo1/carrinho_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override

  Widget build(BuildContext context) {
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CarrinhoProvider()),
      ],
    child: Consumer<AuthProvider>(
      builder: (context, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.theme,
            home: auth.isLoggedIn ? const Navigation() : const Login(),
          );
      },
    )
    );
    //   return MultiProvider(
    //     providers: [ChangeNotifierProvider(create: (context) => AuthState())],
    //     builder: (context, child) => MaterialApp(
    //       title: 'Flutter Demo',
    //       theme: ThemeData(
    //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    //       ),
    //       home: Consumer<AuthState>(
    //         builder: (context, authState, _) {
    //           return authState.isAuthorized
    //               ? const MainHomeScreen()
    //               : FutureBuilder(
    //                   future: authState.isLoggedIn(),
    //                   builder: (context, snapshot) =>
    //                       snapshot.connectionState == ConnectionState.waiting
    //                       ? const SplashScreen()
    //                       : authState.displayedOnboard
    //                       ? const Login()
    //                       : const Cadastro(),
    //                 );
    //         },
    //       ),
    //     ),
    //   );
}
}
