import 'package:flutter_test/flutter_test.dart';

import 'package:markdown_editor/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MarkdownEditorApp());
    expect(find.text('历史记录'), findsOneWidget);
  });
}
