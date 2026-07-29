import 'package:flutter/material.dart';
import 'package:flutter_blog_app/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          children: [
            Consumer<AuthProvider>(
              builder: (context, value, child) => ListTile(
                leading: const Icon(Icons.person),
                title: Text(value.currentProfile?.name ?? "No user"),
                subtitle: Text(value.currentSession?.user.email ?? 'No email'),
              ),
            ),
            ListTile(
              title: Text("Change Name"),
              leading: const Icon(Icons.edit),
              onTap: () => context.pushNamed('change_username'),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hoverColor: Colors.red.withValues(alpha: 0.08),
              onTap: () {
                context.read<AuthProvider>().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
