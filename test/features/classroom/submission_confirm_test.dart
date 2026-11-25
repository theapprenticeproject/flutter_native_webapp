import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_submitted_preview.dart';
import 'package:tapapp/features/classroom/presentation/widgets/submission_confirm_dialog.dart';

/// Design M-S-03 (check the work before it is sent) and M-S-04 ("Sending… 60%").
void main() {
  testWidgets('the confirm screen: Send and Change file', (tester) async {
    var sent = 0;
    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubmissionConfirmDialog(
            bytes: null,
            isVideo: false,
            onSend: () => sent++,
            onChange: () => changed++,
          ),
        ),
      ),
    );
    expect(find.text('Check your work before sending'), findsOneWidget);
    expect(find.text('Photo - right kind for this activity'), findsOneWidget);
    await tester.tap(find.text('Send to TAP Buddy'));
    await tester.tap(find.text('Change file'));
    expect([sent, changed], [1, 1]);
  });

  testWidgets('the preview shows "Sending… 60%" while the upload runs', (
    tester,
  ) async {
    final progress = ValueNotifier<double?>(0.6);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClassSubmittedPreview(
            bytes: Uint8List(0),
            isVideo: true,
            progress: progress,
          ),
        ),
      ),
    );
    expect(find.text('Sending… 60%'), findsOneWidget);
    progress.value = null;
    await tester.pump();
    expect(find.textContaining('Sending'), findsNothing);
  });
}
