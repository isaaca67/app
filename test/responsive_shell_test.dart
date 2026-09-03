import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_cov_dark_mobile_login/features/layout/widgets/responsive_shell.dart';

void main() {
  const destinations = [
    ShellDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Inicio',
    ),
    ShellDestination(
      icon: Icons.inventory_2_outlined,
      selectedIcon: Icons.inventory_2,
      label: 'Catálogo',
    ),
  ];

  Widget buildShell() => MaterialApp(
    home: ResponsiveShell(
      destinations: destinations,
      tabs: const [SizedBox(), SizedBox()],
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      title: 'COV',
    ),
  );

  testWidgets('usa etiquetas compatibles con NavigationRail compacto', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 700);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildShell());

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isFalse);
    expect(rail.labelType, NavigationRailLabelType.all);
    expect(tester.takeException(), isNull);
  });

  testWidgets('usa labelType none cuando NavigationRail está extendido', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildShell());

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.labelType, NavigationRailLabelType.none);
    expect(tester.takeException(), isNull);
  });
}
