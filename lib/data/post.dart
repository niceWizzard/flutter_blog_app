class Post {
  final List<String> imageUrls;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String id;
  Post({
    required this.createdAt,
    required this.description,
    required this.title,
    required this.updatedAt,
    required this.imageUrls,
    required this.id,
  });

  Post copyWith({
    List<String>? imageUrls,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id,
      imageUrls: imageUrls ?? this.imageUrls,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
