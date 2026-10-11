// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:street_cloud/main.dart';
import 'package:street_cloud/api/client.dart';
import 'package:street_cloud/theme/app_theme.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    final api = ApiClient();
    final theme = ThemeController();
    await tester.pumpWidget(StreetCloudApp(api: api, theme: theme));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
