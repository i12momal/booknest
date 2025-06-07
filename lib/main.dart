import 'package:booknest/services/base_service.dart';
import 'package:booknest/views/reset_password_view.dart';
import 'package:booknest/views/splash_video_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  try {
    await BaseService.initialize();
  } catch (e) {
    print('Error al inicializar Supabase: $e');
  }

  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() async {
    final initialUri = await _appLinks.getInitialAppLink();
    _processUri(initialUri);

    _appLinks.uriLinkStream.listen((Uri uri) {
      _processUri(uri);
    });
  }

  Future<void> _processUri(Uri? uri) async {
    if (uri != null && uri.scheme == 'booknest' && uri.host == 'reset-password') {
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        debugPrint('Sesión iniciada desde el enlace');
      } catch (e) {
        debugPrint('Error al obtener la sesión: $e');
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const ResetPasswordView(fromDeepLink: true)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'BookNest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: kIsWeb ? const MyHomePage(title: '') : const SplashVideoPage(),
    );
  }
}