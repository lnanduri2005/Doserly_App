import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';

import 'models/medicine.dart';
import 'services/notification_service.dart';
import 'providers/medicine_provider.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/add_edit_screen.dart';
import 'screens/medicine_details_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Register Hive adapters
  Hive.registerAdapter(MedicineAdapter());

  // Open the medicine box
  await Hive.openBox<Medicine>('medicines');

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();

  // Set preferred orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(DoserlyApp());
}

class DoserlyApp extends StatelessWidget {
  const DoserlyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MedicineProvider(
            NotificationService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Doserly',
        theme: DoserlyTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => HomeScreen(),
          '/add-medicine': (context) => AddEditMedicineScreen(),
          '/edit-medicine': (context) => AddEditMedicineScreen(isEditing: true),
          '/medicine-details': (context) => MedicineDetailsScreen(),
          '/settings': (context) => SettingsScreen(),
        },
      ),
    );
  }
}
