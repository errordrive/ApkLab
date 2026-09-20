import 'package:flutter_test/flutter_test.dart';
import 'package:apklab/main.dart';

void main() {
  testWidgets('ApkLab smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ApkLabApp());
    await tester.pumpAndSettle();

    // Verify that ApkLab launches and displays the dashboard
    expect(find.text('APkLab'), findsOneWidget);
    expect(find.text('IMPORT FROM STORAGE'), findsOneWidget);
  });
}
