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
    this.minWideWidth = 600,
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

        return Scaffold(
          appBar: AppBar(title: Text(title)),
          floatingActionButton: floatingActionButton,
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: selectedIndex,
                      onDestinationSelected: onDestinationSelected,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.darkSurface
                              : Colors.white,
                      indicatorColor:
                          AppTheme.primaryColor.withValues(alpha: 0.2),
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
                      destinations: destinations
                          .map(
                            (destination) => NavigationRailDestination(
                              icon: Icon(destination.icon),
                              selectedIcon: Icon(destination.selectedIcon),
                              label: Text(destination.label),
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