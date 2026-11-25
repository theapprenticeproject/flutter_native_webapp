import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_section_checkpoint.dart';

/// QA slide 4: on the first screen of the activity (design M-C01) the message is
/// 16, centered. Ours was 18 and filled the screen.
void main() {
  testWidgets('the message is 16 on a phone', (tester) async {
    tester.view.physicalSize = const Size(412, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClassSectionCheckpoint(
            kind: ClassSectionCheckpointKind.video,
            text: 'Today we are going to play with ScratchJr.',
            buttonLabel: 'Watch',
            onPressed: () {},
          ),
        ),
      ),
    );
    final style = tester
        .widget<Text>(find.textContaining('Today we are going'))
        .style;
    expect(style?.fontSize, 16);
  });
}
