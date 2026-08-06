class Post {
  final List<String> imageUrls;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int id;
  final String? userId;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.updatedAt,
    required this.createdAt,
    required this.description,
    required this.imageUrls,
  });

  Post copyWith({
    int? id,
    String? userId,
    List<String>? imageUrls,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imageUrls: imageUrls ?? this.imageUrls,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
