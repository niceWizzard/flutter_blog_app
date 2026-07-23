class Validation {
  static bool isValidEmail(String value) {
    final emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegExp.hasMatch(value.trim());
  }
}
