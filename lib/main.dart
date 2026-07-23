import 'package:flutter/material.dart';
import 'package:flutter_blog_app/app_router.dart';
import 'package:flutter_blog_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  await Supabase.initialize(
    url: dotenv.env["SUPABASE_URL"]!,
    publishableKey: dotenv.env["SUPABASE_PUBLISHABLE_KEY"]!,
  );

  final authProvider = AuthProvider();
  final appRouter = AppRouter(authProvider: authProvider);
  runApp(MyApp(appRouter: appRouter));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;

  const MyApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: appRouter.authProvider,
        ),
      ],
      child: MaterialApp.router(
        title: 'Flutter Blog App',
        routerConfig: appRouter.routerConfig,
      ),
    );
  }
}
