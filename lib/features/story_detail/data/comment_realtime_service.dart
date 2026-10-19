import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/auth/secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../models/story_comment.dart';

class CommentRealtimeService {
  final SecureStorage _storage;

  io.Socket? _socket;
  String? _storyId;
  bool _connectedOnce = false;
  bool _disposed = false;

  final _createdController = StreamController<StoryComment>.broadcast();
  final _updatedController = StreamController<StoryComment>.broadcast();
  final _deletedController = StreamController<String>.broadcast();
  final _likedController = StreamController<CommentLikeEvent>.broadcast();
  final _typingController =
      StreamController<List<CommentTypingUser>>.broadcast();
  final _syncController = StreamController<void>.broadcast();

  CommentRealtimeService({required SecureStorage storage}) : _storage = storage;

  Stream<StoryComment> get created => _createdController.stream;
  Stream<StoryComment> get updated => _updatedController.stream;
  Stream<String> get deleted => _deletedController.stream;
  Stream<CommentLikeEvent> get liked => _likedController.stream;
  Stream<List<CommentTypingUser>> get typing => _typingController.stream;
  Stream<void> get syncRequested => _syncController.stream;

  Future<void> connect(String storyId) async {
    if (_disposed) return;
    _storyId = storyId;
    final token = await _storage.getAccessToken();
    if (_disposed) return;

    final builder = io.OptionBuilder()
        .setTransports(['websocket'])
        .enableReconnection()
        .disableAutoConnect();

    if (token != null && token.isNotEmpty) {
      builder.setAuth({'token': token});
    }

    final socket = io.io(_commentsSocketUrl, builder.build());
    _socket = socket;

    socket.onConnect((_) {
      if (_disposed) return;
      _joinStoryRoom();
      if (_connectedOnce) _syncController.add(null);
      _connectedOnce = true;
    });
    socket.onReconnect((_) {
      if (!_disposed) _syncController.add(null);
    });
    socket.on('comment.created', (data) {
      if (_disposed) return;
      final comment = _readCommentEvent(data);
      if (comment != null) _createdController.add(comment);
    });
    socket.on('comment.updated', (data) {
      if (_disposed) return;
      final comment = _readCommentEvent(data);
      if (comment != null) _updatedController.add(comment);
    });
    socket.on('comment.deleted', (data) {
      if (_disposed) return;
      final map = _asMap(data);
      final commentId = map?['commentId']?.toString();
      if (commentId != null && commentId.isNotEmpty) {
        _deletedController.add(commentId);
      }
    });
    socket.on('comment.liked', (data) {
      if (_disposed) return;
      final map = _asMap(data);
      if (map == null) return;
      _likedController.add(CommentLikeEvent.fromJson(map));
    });
    socket.on('comment.typing', (data) {
      if (_disposed) return;
      final map = _asMap(data);
      final users = map?['users'];
      if (users is! List) {
        _typingController.add(const []);
        return;
      }
      _typingController.add(
        users
            .whereType<Map>()
            .map(
              (item) =>
                  CommentTypingUser.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(),
      );
    });

    socket.connect();
  }

  void startTyping() {
    if (_disposed) return;
    final storyId = _storyId;
    if (storyId == null) return;
    _socket?.emit('comment_typing_start', {'storyId': storyId});
  }

  void stopTyping() {
    if (_disposed) return;
    final storyId = _storyId;
    if (storyId == null) return;
    _socket?.emit('comment_typing_stop', {'storyId': storyId});
  }

  void dispose() {
    if (_disposed) return;
    final storyId = _storyId;
    if (storyId != null) {
      _socket?.emit('comment_typing_stop', {'storyId': storyId});
      _socket?.emit('leave_story_comments', {'storyId': storyId});
    }
    _disposed = true;
    _socket?.dispose();
    _createdController.close();
    _updatedController.close();
    _deletedController.close();
    _likedController.close();
    _typingController.close();
    _syncController.close();
  }

  void _joinStoryRoom() {
    final storyId = _storyId;
    if (storyId == null) return;
    _socket?.emit('join_story_comments', {'storyId': storyId});
  }

  StoryComment? _readCommentEvent(dynamic data) {
    final map = _asMap(data);
    final comment = map?['comment'];
    if (comment is! Map) return null;
    return StoryComment.fromJson(Map<String, dynamic>.from(comment));
  }

  Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }
}

String get _commentsSocketUrl {
  final base = AppConstants.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
  return '$base/comments';
}
