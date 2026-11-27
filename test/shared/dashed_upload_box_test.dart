import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/shared/widgets/dashed_upload_box.dart';

/// Figma "Submission Drop Zone" (M-S-01): the content sits 26 from the sides and
/// about 34 from the top and bottom of the dotted rectangle. It was 14 all round
/// and looked tight.
void main() {
  testWidgets('there is room between the dotted line and the content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 343,
              child: DashedUploadBox(
                child: SizedBox(key: ValueKey('inside'), height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(DashedUploadBox));
    final inside = tester.getRect(find.byKey(const ValueKey('inside')));
    expect(inside.left - box.left, 26);
    expect(box.right - inside.right, 26);
    expect(inside.top - box.top, 32);
    expect(box.bottom - inside.bottom, 32);
  });

  testWidgets('the upload badge is a 56 round lavender circle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: UploadBadge())),
      ),
    );
    expect(tester.getSize(find.byType(UploadBadge)), const Size(56, 56));
    final box = tester.widget<Container>(find.byType(Container).first);
    expect((box.decoration! as BoxDecoration).color, const Color(0xFFE8E8FB));
  });
}
