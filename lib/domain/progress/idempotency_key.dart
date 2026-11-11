import 'dart:math';

final _random = Random.secure();

/// A key that makes a write safe to send twice (the Worker answers the second
/// call with `repeat: true` and gives no points again).
///
/// Make one key per action, and keep it until the Worker answers. Send the SAME
/// key when you retry that action. A new action gets a new key.
String newIdempotencyKey(String kind, String studentId, String targetId) {
  final nonce = List.generate(
    12,
    (_) => _random.nextInt(16).toRadixString(16),
  ).join();
  return '$kind:$studentId:$targetId:$nonce';
}
