import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/features/classroom/presentation/widgets/class_video_reward_card.dart';

/// QA bug 6: on the video-complete screen (design M-C05) the picture was a
/// full-width square, the text was 18 and the Continue button 76 high, so the
/// message "covered almost the whole screen". The picture is smaller, the text
/// 16, the button the app's standard one.
Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  VoidCallback? onContinue,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: ClassVideoRewardCard(
            image: 'assets/class-screen/10Points.png',
            text:
                'Wow! That’s amazing 🤩  Aarav, you just earned 10 points🪩 for '
                'watching the video 🥳🥳🥳\n\nNow it’s time to do the activity '
                'submission 🌟',
            buttonLabel: 'Continue',
            onContinue: onContinue ?? () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  rewardCardHasFixedPictureHeight();
  testWidgets('the picture is no taller than 240', (tester) async {
    await _pump(tester, size: const Size(412, 900));
    final picture = find.byType(Image);
    expect(tester.getSize(picture).height, lessThanOrEqualTo(240));
  });

  testWidgets('the text is 16', (tester) async {
    await _pump(tester, size: const Size(412, 900));
    final text = tester.widget<Text>(find.textContaining('Wow!'));
    expect(text.style?.fontSize, 16);
  });

  testWidgets('the button is the app\'s standard one: 52 high', (tester) async {
    var taps = 0;
    await _pump(tester, size: const Size(412, 900), onContinue: () => taps++);
    expect(tester.getSize(find.byType(ElevatedButton)).height, 52);
    await tester.tap(find.text('Continue'));
    expect(taps, 1);
  });

  testWidgets('the whole card is under 600 high on a 412 wide phone', (
    tester,
  ) async {
    await _pump(tester, size: const Size(412, 900));
    final card = tester.getSize(find.byType(ClassVideoRewardCard));
    expect(card.height, lessThan(600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('fits a 320 wide phone', (tester) async {
    await _pump(tester, size: const Size(320, 640));
    expect(tester.takeException(), isNull);
  });
}

/// The chat scrolls to the bottom in the frame after the card is added. The
/// picture must have its height at once, else the scroll stops short and the
/// last lines of text stay below the screen (QA, M-C05).
void rewardCardHasFixedPictureHeight() {
  testWidgets('the picture box is 240 high before the picture is decoded', (
    tester,
  ) async {
    await _pump(tester, size: const Size(412, 800));
    final box = tester.widget<SizedBox>(
      find.byKey(const ValueKey('reward-picture')),
    );
    expect(box.height, 240);
  });
}
