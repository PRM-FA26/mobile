/// Core domain models shared across features.
///
/// Mirrors the TypeScript interfaces from the web frontend.
library;

class Story {
  final String id;
  final String title;
  final String? description;
  final String? coverImage;
  final String? type; // NOVEL, MANGA, etc.
  final String? status; // ONGOING, COMPLETED
  final int? viewCount;
  final double? rating;
  final AuthorBrief? author;
  final List<Genre>? genres;
  final int? chapterCount;

  const Story({
    required this.id,
    required this.title,
    this.description,
    this.coverImage,
    this.type,
    this.status,
    this.viewCount,
    this.rating,
    this.author,
    this.genres,
    this.chapterCount,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    // Handle `_count.chapters` from backend
    final count = json['_count'];
    final chapterCount = count is Map ? count['chapters'] as int? : null;

    // Handle nested genre format: { genre: { id, name } } or { id, name }
    final rawGenres = json['genres'] as List?;
    final genres = rawGenres?.map((g) {
      if (g is Map && g.containsKey('genre')) {
        return Genre.fromJson(g['genre'] as Map<String, dynamic>);
      }
      return Genre.fromJson(g as Map<String, dynamic>);
    }).toList();

    // Handle author format
    AuthorBrief? author;
    if (json['author'] != null) {
      final a = json['author'] as Map<String, dynamic>;
      author = AuthorBrief(
        id: a['id'] as String,
        name: (a['name'] ?? a['displayName'] ?? a['username'] ?? 'Unknown')
            as String,
        displayName: a['displayName'] as String?,
        username: a['username'] as String?,
      );
    }

    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImage: json['coverImage'] as String?,
      type: json['type'] as String?,
      status: json['status'] as String?,
      viewCount: json['viewCount'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      author: author,
      genres: genres,
      chapterCount: chapterCount ?? json['totalChapters'] as int? ?? json['chapterCount'] as int?,
    );
  }
}

class AuthorBrief {
  final String id;
  final String name;
  final String? displayName;
  final String? username;

  const AuthorBrief({
    required this.id,
    required this.name,
    this.displayName,
    this.username,
  });
}

class Genre {
  final String id;
  final String name;

  const Genre({required this.id, required this.name});

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class Chapter {
  final String id;
  final String title;
  final int chapterNumber;
  final String? content;
  final bool isPremium;
  final int? price;
  final int? wordCount;
  final DateTime? createdAt;
  final bool? isPurchased;

  const Chapter({
    required this.id,
    required this.title,
    required this.chapterNumber,
    this.content,
    this.isPremium = false,
    this.price,
    this.wordCount,
    this.createdAt,
    this.isPurchased,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as String,
        title: json['title'] as String,
        chapterNumber: json['chapterNumber'] as int,
        content: json['content'] as String?,
        isPremium: json['isPremium'] as bool? ?? false,
        price: json['price'] as int?,
        wordCount: json['wordCount'] as int?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
        isPurchased: json['isPurchased'] as bool?,
      );
}

class HistoryItem {
  final String id;
  final DateTime readAt;
  final double progress;
  final Story story;
  final ChapterBrief chapter;

  const HistoryItem({
    required this.id,
    required this.readAt,
    required this.progress,
    required this.story,
    required this.chapter,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String,
        readAt: DateTime.parse((json['readAt'] ?? json['updatedAt'] ?? json['createdAt']) as String),
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        story: Story.fromJson(json['story'] as Map<String, dynamic>),
        chapter:
            ChapterBrief.fromJson(json['chapter'] as Map<String, dynamic>),
      );
}

class ChapterBrief {
  final String id;
  final String title;
  final int chapterNumber;

  const ChapterBrief({
    required this.id,
    required this.title,
    required this.chapterNumber,
  });

  factory ChapterBrief.fromJson(Map<String, dynamic> json) => ChapterBrief(
        id: json['id'] as String,
        title: json['title'] as String,
        chapterNumber: json['chapterNumber'] as int,
      );
}

class PaginatedResponse<T> {
  final List<T> data;
  final int totalPages;
  final int currentPage;

  const PaginatedResponse({
    required this.data,
    required this.totalPages,
    required this.currentPage,
  });
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final String? link;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.link,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        link: json['link'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        link: link,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

/// A user's profile as returned by `GET /users/me` and `GET /users/:id`.
/// Covers both the current user's own profile screen and public
/// user-profile pages, which the backend serves in the same shape.
class ProfileDetails {
  final String username;
  final String? displayName;
  final String? avatar;
  final String? bio;
  final String role; // READER, WRITER, ADMIN
  final int followersCount;
  final int followingCount;
  final int storiesCount;

  const ProfileDetails({
    required this.username,
    this.displayName,
    this.avatar,
    this.bio,
    this.role = 'READER',
    this.followersCount = 0,
    this.followingCount = 0,
    this.storiesCount = 0,
  });

  factory ProfileDetails.fromJson(Map<String, dynamic> json) {
    final count = json['_count'] as Map<String, dynamic>?;
    return ProfileDetails(
      username: json['username'] as String? ?? '',
      displayName: json['displayName'] as String?,
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String? ?? 'READER',
      followersCount: (count?['followers'] as num?)?.toInt() ?? 0,
      followingCount: (count?['following'] as num?)?.toInt() ?? 0,
      storiesCount: (count?['stories'] as num?)?.toInt() ?? 0,
    );
  }

  bool get isWriter => role == 'WRITER';

  String get resolvedDisplayName {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? username : name;
  }
}
