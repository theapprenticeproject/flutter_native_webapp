import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/router/router.dart';
import '../core/theme/app_theme.dart';
import 'tap_buddy_panel.dart';

class AppNav extends StatefulWidget {
  final Widget child;

  const AppNav({super.key, required this.child});

  @override
  State<AppNav> createState() => _AppNavState();
}

class _AppNavState extends State<AppNav> {
  bool _tapBuddyOpen = false;

  static const _items = [
    _NavDestination(AppRoutes.home, Icons.home_outlined, 'Home'),
    _NavDestination(AppRoutes.classroom, Icons.school_outlined, 'Class'),
    _NavDestination(AppRoutes.passport, Icons.badge_outlined, 'Passport'),
    _NavDestination(
      AppRoutes.profile,
      Icons.account_circle_outlined,
      'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: TapBuddyScope(
        openPanel: () => setState(() => _tapBuddyOpen = true),
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            if (_tapBuddyOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _tapBuddyOpen = false),
                  child: Container(color: Colors.black.withValues(alpha: 0.48)),
                ),
              ),
              TapBuddyPanel(
                onClose: () => setState(() => _tapBuddyOpen = false),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(items: _items),
    );
  }
}

class TapBuddyScope extends InheritedWidget {
  final VoidCallback openPanel;

  const TapBuddyScope({
    super.key,
    required this.openPanel,
    required super.child,
  });

  static VoidCallback? maybeOpenOf(BuildContext context) {
    final scope = context
        .getElementForInheritedWidgetOfExactType<TapBuddyScope>()
        ?.widget;
    return scope is TapBuddyScope ? scope.openPanel : null;
  }

  @override
  bool updateShouldNotify(TapBuddyScope oldWidget) {
    return openPanel != oldWidget.openPanel;
  }
}

class _BottomNav extends StatelessWidget {
  final List<_NavDestination> items;

  const _BottomNav({required this.items});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 76,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE9E9F1))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final item in items)
                Flexible(
                  fit: FlexFit.loose,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width > 700 ? 180 : null,
                    child: _NavItem(item: item, active: location == item.route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavDestination item;
  final bool active;

  const _NavItem({required this.item, required this.active});

  void _navigate(BuildContext context) {
    if (active) return;
    final route = item.route;
    final router = GoRouter.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigate(context),
      child: Center(
        child: active
            ? Container(
                width: 80,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.buttonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 18, color: Colors.white),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF747583),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Icon(item.icon, size: 14, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7A7B8E),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NavDestination {
  final String route;
  final IconData icon;
  final String label;

  const _NavDestination(this.route, this.icon, this.label);
}
