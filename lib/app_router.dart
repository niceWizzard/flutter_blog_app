import 'package:flutter_blog_app/providers/auth_provider.dart';
import 'package:flutter_blog_app/screens/home_screen.dart';
import 'package:flutter_blog_app/screens/login_screen.dart';
import 'package:flutter_blog_app/screens/posts_tab.dart';
import 'package:flutter_blog_app/screens/profile_tab.dart';
import 'package:flutter_blog_app/screens/register_screen.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  final AuthProvider authProvider;
  AppRouter({required this.authProvider});

  late final routerConfig = GoRouter(
    initialLocation: '/posts',
    refreshListenable: authProvider,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeScreen(shell: navigationShell),
        redirect: (context, state) =>
            authProvider.isAuthenticated ? null : '/auth/login',
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/posts',
                name: 'posts',
                builder: (context, state) => const PostsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileTab(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/auth',
        redirect: (context, state) =>
            authProvider.isAuthenticated ? '/posts' : null,
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),
    ],
  );
}
