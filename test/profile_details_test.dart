import 'package:flutter_test/flutter_test.dart';
import 'package:chapterone_mobile/shared/models/models.dart';

void main() {
  group('ProfileDetails.fromJson', () {
    test('parses a full profile payload including nested _count', () {
      final profile = ProfileDetails.fromJson({
        'username': 'alice',
        'displayName': 'Alice B.',
        'avatar': 'https://example.com/a.png',
        'bio': 'Hello world',
        'role': 'WRITER',
        '_count': {'followers': 10, 'following': 3, 'stories': 2},
      });

      expect(profile.username, 'alice');
      expect(profile.displayName, 'Alice B.');
      expect(profile.avatar, 'https://example.com/a.png');
      expect(profile.bio, 'Hello world');
      expect(profile.role, 'WRITER');
      expect(profile.isWriter, true);
      expect(profile.followersCount, 10);
      expect(profile.followingCount, 3);
      expect(profile.storiesCount, 2);
    });

    test('defaults role to READER and counts to 0 when missing', () {
      final profile = ProfileDetails.fromJson({'username': 'bob'});

      expect(profile.role, 'READER');
      expect(profile.isWriter, false);
      expect(profile.followersCount, 0);
      expect(profile.followingCount, 0);
      expect(profile.storiesCount, 0);
    });
  });

  group('ProfileDetails.resolvedDisplayName', () {
    test('prefers displayName, falls back to username when blank or absent', () {
      final withName = ProfileDetails.fromJson({'username': 'carol', 'displayName': 'Carol C.'});
      final blankName = ProfileDetails.fromJson({'username': 'dave', 'displayName': '   '});
      final noName = ProfileDetails.fromJson({'username': 'eve'});

      expect(withName.resolvedDisplayName, 'Carol C.');
      expect(blankName.resolvedDisplayName, 'dave');
      expect(noName.resolvedDisplayName, 'eve');
    });
  });
}
