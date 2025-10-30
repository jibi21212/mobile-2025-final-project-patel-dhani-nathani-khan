import 'package:flutter/material.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Collaborative Task Manager',
      theme: ThemeData(useMaterial3: true),
      routerConfig: appRouter,
    );
  }
}
