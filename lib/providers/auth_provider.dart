import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;

  AuthProvider() {
    // 1. Listen to Supabase auth events in real-time
    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen((data) {
      // 2. Notify GoRouter listeners whenever the auth state changes
      notifyListeners();
    });
  }

  // Check if session exists (true if user is authenticated)
  bool get isAuthenticated => _supabaseClient.auth.currentSession != null;
  Session? get currentSession => _supabaseClient.auth.currentSession;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  // Clean up stream when provider is destroyed
  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
