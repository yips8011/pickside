import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PollCommunityApp()));
    await tester.pump();

    expect(find.byIcon(Icons.how_to_vote_rounded), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
