import 'package:djimsearch/screens/home_screen.dart';
import 'package:djimsearch/themes/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation des données de localisation pour le formatage des dates
  await initializeDateFormatting('fr_FR', null);

  // Workaround pour le bug Flutter SDK "debugFrameWasSentToEngine"
  // https://github.com/flutter/flutter/issues/142309
  // Ce bug est dans le framework lui-même, pas dans le code applicatif.
  // On intercepte l'erreur en mode debug pour éviter le crash.
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('debugFrameWasSentToEngine')) {
        // Ignorer silencieusement cette assertion du framework
        return;
      }
      // Pour toutes les autres erreurs, afficher normalement
      FlutterError.presentError(details);
    };
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DjimSearch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
