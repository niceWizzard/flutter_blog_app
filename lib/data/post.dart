class PostComment {
  final int id;
  final int postId;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final String commenterName;

  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.commenterName,
  });
}

class Post {
  final List<String> imageUrls;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final String? userId;
  final int commentsCount;
  final int viewsCount;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.updatedAt,
    required this.createdAt,
    required this.description,
    required this.imageUrls,
    this.commentsCount = 0,
    this.viewsCount = 0,
  });

  Post copyWith({
    int? id,
    String? userId,
    List<String>? imageUrls,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? commentsCount,
    int? viewsCount,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }
}
