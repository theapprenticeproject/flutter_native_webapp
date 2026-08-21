import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapapp/widgets/error_view.dart';

void main() {
  Widget buildTestableWidget(Size size) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: ErrorView(
          title: 'Something went wrong',
          message: 'We had trouble loading this page.',
          buttonText: 'Try Again',
          desktopTitle: 'Hey Champ\nI am not able to talk to you',
          desktopMessage: "Looks like you're offline.",
          desktopButtonText: 'Retry',
          onRetry: () {},
        ),
      ),
    );
  }

  testWidgets('Renders Mobile layout when screen width is under 600', (
    WidgetTester tester,
  ) async {

    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableWidget(const Size(400, 800)));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.text('Hey Champ\nI am not able to talk to you'), findsNothing);

    tester.view.resetPhysicalSize();
  });

  testWidgets('Renders Desktop layout when screen width is over 600', (
    WidgetTester tester,
  ) async {

    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(buildTestableWidget(const Size(1024, 768)));
    await tester.pumpAndSettle();

    expect(
      find.text('Hey Champ\nI am not able to talk to you'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);

    tester.view.resetPhysicalSize();
  });
}
