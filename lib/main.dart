import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/state/app_state.dart';
import 'presentation/widgets/responsive_scaffold.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/analyzer_screen.dart';
import 'presentation/screens/classes_screen.dart';
import 'presentation/screens/smali_screen.dart';
import 'presentation/screens/jadx_screen.dart';
import 'presentation/screens/dialog_scanner_screen.dart';
import 'presentation/screens/references_screen.dart';
import 'presentation/screens/patch_center_screen.dart';
import 'presentation/screens/reports_screen.dart';
import 'presentation/screens/logs_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('ApkLab FlutterError: ${details.exception}');
  };
  runApp(const ApkLabApp());
}

class ApkLabApp extends StatelessWidget {
  const ApkLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'ApkLab',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const ApkLabHomeScreen(),
      ),
    );
  }
}

class ApkLabHomeScreen extends StatelessWidget {
  const ApkLabHomeScreen({super.key});

  Widget _buildBody(int navIndex) {
    switch (navIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const AnalyzerScreen();
      case 2:
        return const ClassesScreen();
      case 3:
        return const SmaliScreen();
      case 4:
        return const JadxScreen();
      case 5:
        return const DialogScannerScreen();
      case 6:
        return const ReferencesScreen();
      case 7:
        return const PatchCenterScreen();
      case 8:
        return const ReportsScreen();
      case 9:
        return const LogsScreen();
      case 10:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = context.watch<AppState>().selectedNavIndex;
    return ResponsiveScaffold(
      body: _buildBody(navIndex),
    );
  }
}
