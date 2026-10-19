class CommentUser {
  final String id;
  final String username;
  final String? displayName;
  final String? avatar;

  const CommentUser({
    required this.id,
    required this.username,
    this.displayName,
    this.avatar,
  });

  factory CommentUser.fromJson(Map<String, dynamic> json) {
    return CommentUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'user',
      displayName: json['displayName']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }

  String get displayNameOrUsername {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? username : name;
  }

  String get initial {
    final source = displayNameOrUsername.trim();
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }
}

class StoryComment {
  final String id;
  final String storyId;
  final String userId;
  final String content;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CommentUser? user;
  final bool isLiked;
  final int likesCount;

  const StoryComment({
    required this.id,
    required this.storyId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.user,
    this.isLiked = false,
    this.likesCount = 0,
  });

  factory StoryComment.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final countJson = json['_count'];
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final updatedAt = DateTime.tryParse(json['updatedAt']?.toString() ?? '');

    return StoryComment(
      id: json['id']?.toString() ?? '',
      storyId: json['storyId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      parentId: json['parentId']?.toString(),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
      user: userJson is Map
          ? CommentUser.fromJson(Map<String, dynamic>.from(userJson))
          : null,
      isLiked: json['isLiked'] as bool? ?? false,
      likesCount: _readInt(
        json['likesCount'] ??
            json['likeCount'] ??
            (countJson is Map ? countJson['likes'] : null),
      ),
    );
  }

  StoryComment copyWith({
    String? content,
    DateTime? updatedAt,
    bool? isLiked,
    int? likesCount,
  }) {
    return StoryComment(
      id: id,
      storyId: storyId,
      userId: userId,
      content: content ?? this.content,
      parentId: parentId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}

class CommentLikeEvent {
  final String commentId;
  final int likesCount;
  final String userId;
  final bool isLiked;

  const CommentLikeEvent({
    required this.commentId,
    required this.likesCount,
    required this.userId,
    required this.isLiked,
  });

  factory CommentLikeEvent.fromJson(Map<String, dynamic> json) {
    return CommentLikeEvent(
      commentId: json['commentId']?.toString() ?? '',
      likesCount: _readInt(json['likesCount']),
      userId: json['userId']?.toString() ?? '',
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }
}

class CommentTypingUser {
  final String id;
  final String username;
  final String? displayName;

  const CommentTypingUser({
    required this.id,
    required this.username,
    this.displayName,
  });

  factory CommentTypingUser.fromJson(Map<String, dynamic> json) {
    return CommentTypingUser(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'user',
      displayName: json['displayName']?.toString(),
    );
  }

  String get displayNameOrUsername {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? username : name;
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
