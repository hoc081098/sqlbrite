class Item {
  final int? id;
  final String content;
  final DateTime createdAt;

  const Item(
    this.id,
    this.content,
    this.createdAt,
  );

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      json['id'],
      json['content'],
      DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Item copyWith(String content) => Item(id, content, createdAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Item &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          content == other.content &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ content.hashCode ^ createdAt.hashCode;

  @override
  String toString() =>
      'Item{id: $id, content: $content, createdAt: $createdAt}';
}
