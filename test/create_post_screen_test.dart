import 'package:flutter/material.dart';
import 'package:flutter_blog_app/screens/create_post_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Create post screen shows form fields and image guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));

    expect(find.text('Create Post'), findsNWidgets(2));
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.textContaining('up to 5 images'), findsOneWidget);
  });
}
