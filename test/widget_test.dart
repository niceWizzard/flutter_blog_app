import 'package:flutter/material.dart';
import 'package:flutter_blog_app/data/post.dart';
import 'package:flutter_blog_app/providers/post_provider.dart';
import 'package:flutter_blog_app/screens/create_post_screen.dart';
import 'package:flutter_blog_app/screens/posts_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakePostProvider extends PostProvider {
  FakePostProvider(this.posts);

  final List<Post> posts;
  int getPublicPostsCallCount = 0;

  @override
  Future<List<Post>> getPublicPosts({
    int limit = 10,
    int offset = 0,
    String sort = 'recent',
    String? search,
  }) async {
    getPublicPostsCallCount++;
    final query = (search ?? '').trim().toLowerCase();
    var filteredPosts = posts.where((post) {
      final haystack = '${post.title} ${post.description}'.toLowerCase();
      return query.isEmpty || haystack.contains(query);
    }).toList();

    filteredPosts.sort((a, b) {
      if (sort == 'oldest') {
        return a.createdAt.compareTo(b.createdAt);
      }
      if (sort == 'comments') {
        return b.commentsCount.compareTo(a.commentsCount);
      }
      if (sort == 'views') {
        return b.viewsCount.compareTo(a.viewsCount);
      }
      if (sort == 'title') {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    final end = (offset + limit).clamp(0, filteredPosts.length);
    return filteredPosts.sublist(offset, end);
  }
}

void main() {
  testWidgets('Create post screen renders its form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreatePostScreen()));

    expect(find.text('Create Post'), findsNWidgets(2));
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
  });

  testWidgets('Posts tab shows a load-more control when more pages exist', (
    tester,
  ) async {
    final provider = FakePostProvider(
      List.generate(
        15,
        (index) => Post(
          id: index + 1,
          userId: 'user-$index',
          title: 'Post $index',
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
          description: 'Description $index',
          imageUrls: const [],
        ),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PostProvider>.value(
        value: provider,
        child: const MaterialApp(home: PostsTab()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(provider.getPublicPostsCallCount, 2);
  });

  testWidgets('Posts tab supports searching posts', (tester) async {
    final provider = FakePostProvider([
      Post(
        id: 1,
        userId: 'user-1',
        title: 'Summer getaway',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'A bright trip idea',
        imageUrls: const [],
      ),
      Post(
        id: 2,
        userId: 'user-2',
        title: 'Winter retreat',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        description: 'A cozy cabin plan',
        imageUrls: const [],
      ),
    ]);

    await tester.pumpWidget(
      ChangeNotifierProvider<PostProvider>.value(
        value: provider,
        child: const MaterialApp(home: PostsTab()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'summer');
    await tester.pump();

    expect(find.text('Summer getaway'), findsOneWidget);
    expect(find.text('Winter retreat'), findsNothing);
  });
}
