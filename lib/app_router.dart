import 'package:flutter_blog_app/providers/auth_provider.dart';
import 'package:flutter_blog_app/screens/home_screen.dart';
import 'package:flutter_blog_app/screens/login_screen.dart';
import 'package:flutter_blog_app/screens/register_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthProvider authProvider;
  AppRouter({required this.authProvider});

  late final routerConfig = GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        redirect: (context, state) =>
            authProvider.isAuthenticated ? null : '/auth/login',
      ),
      GoRoute(
        path: '/auth',
        redirect: (context, state) => authProvider.isAuthenticated ? '/' : null,
        routes: [
          GoRoute(
            path: 'login',
            name: "login",
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            name: "register",
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
    ],
  );
}
