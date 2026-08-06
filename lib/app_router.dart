import 'package:flutter_blog_app/providers/auth_provider.dart';
import 'package:flutter_blog_app/screens/change_username_screen.dart';
import 'package:flutter_blog_app/screens/create_post_screen.dart';
import 'package:flutter_blog_app/screens/home_screen.dart';
import 'package:flutter_blog_app/screens/login_screen.dart';
import 'package:flutter_blog_app/screens/post_detail_screen.dart';
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
        path: '/posts/new',
        name: 'create_post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/posts/:postId',
        name: 'post_detail',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/change_username',
        name: 'change_username',
        builder: (context, state) => const ChangeUsernameScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        redirect: (context, state) =>
            authProvider.isAuthenticated ? '/posts' : null,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        redirect: (context, state) =>
            authProvider.isAuthenticated ? '/posts' : null,
        builder: (context, state) => const RegisterScreen(),
      ),
    ],
  );
}
