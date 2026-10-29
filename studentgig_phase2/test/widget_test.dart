import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:studentgig/core/router/app_router.dart';
import 'package:studentgig/domain/entities/app_user.dart';
import 'package:studentgig/features/auth/application/auth_providers.dart';
import 'package:studentgig/features/dashboard/presentation/dashboard_screen.dart';
import 'package:studentgig/main.dart';

void main() {
  testWidgets('StudentGigApp displays the routed screen', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: Text('StudentGig test')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [routerProvider.overrideWithValue(router)],
        child: const StudentGigApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('StudentGig test'), findsOneWidget);

    router.dispose();
  });

  testWidgets('student dashboard saves gigs and adapts to mobile layout',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => Stream.value(
              AppUser(
                id: 'student-1',
                email: 'student@example.com',
                displayName: 'Taylor Student',
                role: UserRole.student,
                createdAt: DateTime(2026),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(role: UserRole.student),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Hi, Taylor.'), findsOneWidget);
    expect(find.text('Campus Brand Ambassador'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.bySemanticsLabel('StudentGig app icon'), findsOneWidget);

    await tester.tap(find.byTooltip('Save gig').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();

    expect(find.text('Campus Brand Ambassador'), findsOneWidget);
    expect(find.text('Saved gigs'), findsOneWidget);
  });

  testWidgets('employer can publish and remove a gig', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => Stream.value(null))
        ],
        child: const MaterialApp(
          home: DashboardScreen(role: UserRole.employer),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post a gig'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Library Assistant');
    await tester.enterText(fields.at(1), 'Campus Library');
    await tester.enterText(fields.at(2), 'On campus');
    await tester.enterText(fields.at(3), '\$19 / hour');
    final publishButton = find.text('Publish gig');
    await tester.ensureVisible(publishButton);
    await tester.tap(publishButton);
    await tester.pumpAndSettle();

    expect(find.text('Create a gig'), findsNothing);
    expect(find.text('Your gig is now live.'), findsOneWidget);
    await tester.tap(find.text('My gigs'));
    await tester.pumpAndSettle();
    expect(find.text('Library Assistant'), findsOneWidget);

    final createdGigDelete = find.descendant(
      of: find
          .ancestor(
            of: find.text('Library Assistant'),
            matching: find.byType(Card),
          )
          .first,
      matching: find.byTooltip('Delete gig'),
    );
    await tester.tap(createdGigDelete);
    await tester.pumpAndSettle();
    expect(find.text('Library Assistant'), findsNothing);
  });
}
