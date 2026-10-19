import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/features/story_detail/models/story_comment.dart';

void main() {
  group('StoryComment.fromJson', () {
    test('parses a full comment payload', () {
      final comment = StoryComment.fromJson({
        'id': 'c1',
        'storyId': 's1',
        'userId': 'u1',
        'content': 'Hay quá!',
        'parentId': null,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-02T00:00:00.000Z',
        'user': {'id': 'u1', 'username': 'alice', 'displayName': 'Alice'},
        'isLiked': true,
        'likesCount': 5,
      });

      expect(comment.id, 'c1');
      expect(comment.content, 'Hay quá!');
      expect(comment.user?.displayNameOrUsername, 'Alice');
      expect(comment.isLiked, true);
      expect(comment.likesCount, 5);
    });

    test('reads likesCount from nested _count.likes when likesCount is absent', () {
      final comment = StoryComment.fromJson({
        'id': 'c1',
        'storyId': 's1',
        'userId': 'u1',
        'content': 'Hello',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        '_count': {'likes': 3},
      });

      expect(comment.likesCount, 3);
    });

    test('falls back to safe defaults for missing/malformed fields', () {
      final comment = StoryComment.fromJson({'id': 'c2'});

      expect(comment.storyId, '');
      expect(comment.content, '');
      expect(comment.user, isNull);
      expect(comment.isLiked, false);
      expect(comment.likesCount, 0);
      // createdAt/updatedAt must never be null even when absent from the payload.
      expect(comment.createdAt, isNotNull);
      expect(comment.updatedAt, isNotNull);
    });
  });

  group('CommentUser.displayNameOrUsername', () {
    test('prefers displayName, falls back to username when blank', () {
      const withDisplayName = CommentUser(id: '1', username: 'bob', displayName: 'Bob B.');
      const blankDisplayName = CommentUser(id: '2', username: 'carol', displayName: '   ');
      const noDisplayName = CommentUser(id: '3', username: 'dave');

      expect(withDisplayName.displayNameOrUsername, 'Bob B.');
      expect(blankDisplayName.displayNameOrUsername, 'carol');
      expect(noDisplayName.displayNameOrUsername, 'dave');
    });

    test('initial is the first uppercased character', () {
      const user = CommentUser(id: '1', username: 'eve', displayName: 'eve nguyen');
      expect(user.initial, 'E');
    });
  });

  group('CommentLikeEvent.fromJson', () {
    test('parses likesCount whether sent as int or numeric string', () {
      final fromInt = CommentLikeEvent.fromJson({
        'commentId': 'c1',
        'likesCount': 4,
        'userId': 'u1',
        'isLiked': true,
      });
      final fromString = CommentLikeEvent.fromJson({
        'commentId': 'c1',
        'likesCount': '4',
        'userId': 'u1',
        'isLiked': true,
      });

      expect(fromInt.likesCount, 4);
      expect(fromString.likesCount, 4);
    });
  });

  group('StoryComment.copyWith', () {
    test('preserves fields not overridden', () {
      final original = StoryComment.fromJson({
        'id': 'c1',
        'storyId': 's1',
        'userId': 'u1',
        'content': 'original',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
        'isLiked': false,
        'likesCount': 1,
      });

      final updated = original.copyWith(isLiked: true, likesCount: 2);

      expect(updated.id, original.id);
      expect(updated.content, original.content);
      expect(updated.isLiked, true);
      expect(updated.likesCount, 2);
    });
  });
}
