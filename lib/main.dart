import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'widgets/auto_accept_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Kovai Bites',
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AutoAcceptHost(child: child ?? const SizedBox()),
      theme: appTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}