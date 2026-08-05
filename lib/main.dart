import 'package:flutter/material.dart';
import 'package:flutter_blog_app/app_router.dart';
import 'package:flutter_blog_app/providers/auth_provider.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
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
  final postProvider = PostProvider();
  runApp(MyApp(appRouter: appRouter, postProvider: postProvider));
}

class MyApp extends StatelessWidget {
  final AppRouter appRouter;
  final PostProvider postProvider;

  const MyApp({super.key, required this.appRouter, required this.postProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: appRouter.authProvider,
        ),
        ChangeNotifierProvider<PostProvider>.value(value: postProvider),
      ],
      child: MaterialApp.router(
        title: 'Flutter Blog App',
        routerConfig: appRouter.routerConfig,
      ),
    );
  }
}
