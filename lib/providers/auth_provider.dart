import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;
  Profile? _currentProfile;

  AuthProvider() {
    // 1. Listen to Supabase auth events in real-time
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((
      data,
    ) async {
      await _refreshProfile();
    });

    _refreshProfile();
  }

  // Check if session exists (true if user is authenticated)
  bool get isAuthenticated => _supabaseClient.auth.currentSession != null;
  Session? get currentSession => _supabaseClient.auth.currentSession;
  Profile? get currentProfile => _currentProfile;

  Future<void> _refreshProfile() async {
    final userId = _supabaseClient.auth.currentSession?.user.id;

    if (userId == null) {
      _currentProfile = null;
      notifyListeners();
      return;
    }

    final profile = await _supabaseClient
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (profile != null) {
      _currentProfile = Profile(
        userId: profile['user_id'],
        name: profile["name"],
      );
    }
    notifyListeners();
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    await _refreshProfile();
    return response;
  }

  Future<AuthResponse> signUp(
    String name,
    String email,
    String password,
  ) async {
    final res = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
    );
    final user = res.user;
    if (user == null) {
      throw Exception(
        'User registered successfully, but no user data returned.',
      );
    }

    await _supabaseClient.from("profiles").insert({
      'name': name,
      'user_id': user.id,
    });

    return res;
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
    _currentProfile = null;
    notifyListeners();
  }

  // Clean up stream when provider is destroyed
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
