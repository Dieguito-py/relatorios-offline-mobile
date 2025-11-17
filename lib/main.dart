import 'package:flutter/material.dart';
import 'package:relatoriooffline/pages/configuracoesPage.dart';
import 'package:relatoriooffline/pages/loginPage.dart';
import 'package:relatoriooffline/pages/homePage.dart';
import 'package:relatoriooffline/pages/menuFormularioPage.dart';
import 'package:relatoriooffline/pages/familiaFormPage.dart';
import 'package:relatoriooffline/pages/reciboFormPage.dart';
import 'package:relatoriooffline/pages/pendentesPage.dart';
import 'package:relatoriooffline/pages/enviadosPage.dart';
import 'package:relatoriooffline/core/database/app_database.dart';
import 'package:relatoriooffline/services/syncService.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SyncService.instance.startMonitoring();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Defesa Civil Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          primary: Colors.orange.shade700,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/menu_formularios': (context) => const MenuFormularioPage(),
        '/familia_form': (context) => const FamiliaFormPage(),
        '/recibo_form': (context) => const ReciboFormPage(),
        '/pendentes': (context) => const PendentesPage(),
        '/enviados': (context) => const EnviadosPage(),
        '/configuracoes': (context) => const ConfiguracoesPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificarAutenticacao();
  }

  Future<void> _verificarAutenticacao() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final auth = await AppDatabase.instance.obterToken();

    if (!mounted) return;

    if (auth != null && auth['token'] != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.shield,
                size: 80,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Defesa Civil',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Relatórios Offline',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

