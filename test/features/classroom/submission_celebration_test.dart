import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/models/class_chat_message_model.dart';
import 'package:tapapp/shared/text/first_name.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_submission_card.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_submitted_preview.dart';

/// QA bugs 11 and 12, the upload celebration (design M-C19): the thread keeps
/// the student's bubbles ("I made this" and the photo), then the card:
/// "Congratulations Aarav! 🥳", a "+25 points" pill, "You did a great job,
/// champion!", with no button inside, then a bubble "I am so proud of you Aarav".
// A 1 x 1 picture.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  ),
);

ClassChatMessage _reward(String name, int points) => ClassChatMessage(
  id: '1',
  stepId: 'SUBMISSION-REWARD',
  sender: ClassChatSender.bot,
  contentType: ClassChatContentType.submissionReward,
  data: {'studentName': name, 'points': points},
);

void main() {
  group('firstName', () {
    test('the design says "Aarav", not the full name', () {
      expect(firstName('Aarav Kumar'), 'Aarav');
      expect(firstName('  Supriya Zinda Hai '), 'Supriya');
      expect(firstName('Asha'), 'Asha');
    });

    test('no name: Champ', () {
      expect(firstName(''), 'Champ');
      expect(firstName('   '), 'Champ');
    });
  });

  group('the Congratulations card', () {
    testWidgets('has the design\'s three lines and no button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassSubmissionRewardCard(
              message: _reward('Aarav Kumar', 25),
            ),
          ),
        ),
      );
      expect(find.text('Congratulations Aarav! 🥳'), findsOneWidget);
      expect(find.text('+25 points'), findsOneWidget);
      expect(find.text('You did a great job, champion!'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.textContaining('pts'), findsNothing);
    });

    testWidgets('the points are the ones the card is given (R-41)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassSubmissionRewardCard(message: _reward('Asha', 30)),
          ),
        ),
      );
      expect(find.text('+30 points'), findsOneWidget);
    });
  });

  group('the bubble with the photo the student sent', () {
    testWidgets('shows the photo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClassSubmittedPreview(bytes: _png, isVideo: false),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a video shows a video tile, not a picture', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClassSubmittedPreview(bytes: null, isVideo: true),
          ),
        ),
      );
      expect(find.byIcon(Icons.videocam_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}
