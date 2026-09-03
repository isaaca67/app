import 'package:flutter/material.dart';
import 'package:stitch_cov_dark_mobile_login/core/theme/app_theme.dart';

/// Definición de un destino de navegación dentro de la [ResponsiveShell].
class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Estructura de navegación responsiva.
///
/// - Pantallas anchas (Web, `>= minWideWidth`): usa un [NavigationRail]
///   lateral izquierdo y el contenido al lado.
/// - Pantallas estrechas (móvil): usa un [NavigationBar] inferior.
///
/// Mantiene la identidad visual COV (fondo negro `#000000` y acentos rosas
/// `#FF7A8A`).
class ResponsiveShell extends StatelessWidget {
  const ResponsiveShell({
    super.key,
    required this.destinations,
    required this.tabs,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.title,
    this.floatingActionButton,
    this.minWideWidth = 760,
  });

  final List<ShellDestination> destinations;
  final List<Widget> tabs;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final String title;
  final Widget? floatingActionButton;
  final double minWideWidth;

  @override
  Widget build(BuildContext context) {
    final content = IndexedStack(index: selectedIndex, children: tabs);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= minWideWidth;
        final useExtendedRail = constraints.maxWidth >= 1100;

        return Scaffold(
          appBar: AppBar(centerTitle: !isWide, title: Text(title)),
          floatingActionButton: floatingActionButton,
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      extended: useExtendedRail,
                      minExtendedWidth: 224,
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      labelType: useExtendedRail
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.darkSurface
                          : Colors.white,
                      indicatorColor: AppTheme.primaryColor.withValues(
                        alpha: 0.2,
                      ),
                      selectedIconTheme: const IconThemeData(
                        color: AppTheme.primaryColor,
                      ),
                      unselectedIconTheme: const IconThemeData(
                        color: Colors.grey,
                      ),
                      selectedLabelTextStyle: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        color: Colors.grey,
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (useExtendedRail) ...[
                              const SizedBox(width: 12),
                              const Text(
                                'COV',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      destinations: destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(destination.icon),
                              ),
                              selectedIcon: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Icon(destination.selectedIcon),
                              ),
                              label: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(destination.label),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: destinations
                      .map(
                        (destination) => NavigationDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: destination.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}
