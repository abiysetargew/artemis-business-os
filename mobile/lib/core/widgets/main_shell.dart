import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  final int currentIndex;

  const MainShell({super.key, required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: AppShadows.md,
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => _onItemTapped(context, index),
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.12),
            elevation: 0,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              _Dest(
                icon: AppIcons.dashboard,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Home',
              ),
              _Dest(
                icon: Icons.point_of_sale_outlined,
                selectedIcon: AppIcons.sales,
                label: 'Sales',
              ),
              _Dest(
                icon: Icons.people_outline,
                selectedIcon: AppIcons.customers,
                label: 'Customers',
              ),
              _Dest(
                icon: Icons.inventory_2_outlined,
                selectedIcon: AppIcons.inventory,
                label: 'Inventory',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/sales');
        break;
      case 2:
        context.go('/customers');
        break;
      case 3:
        context.go('/inventory');
        break;
    }
  }
}

class _Dest extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Dest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationDestination(
      icon: Icon(icon, color: AppTheme.slate500),
      selectedIcon: Icon(selectedIcon, color: AppTheme.primaryColor),
      label: label,
    );
  }
}

/// Branded AppBar that can be reused on every authenticated screen.
/// Falls back to default AppBar styling if [showLogo] is false.
class BrandedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showLogo;
  final Color? backgroundColor;
  final bool useGradient;

  const BrandedAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showLogo = true,
    this.backgroundColor,
    this.useGradient = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    if (!useGradient) {
      return AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLogo) ...[
              const AppLogo(size: 28),
              const SizedBox(width: 10),
            ],
            Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: actions,
        leading: leading,
        backgroundColor: backgroundColor,
      );
    }
    return PreferredSize(
      preferredSize: preferredSize,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.gradientAurora,
          boxShadow: AppShadows.sm,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kToolbarHeight,
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: leading!,
                    ),
                  ),
                if (showLogo) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: AppLogo(size: 28),
                  ),
                ] else if (leading == null)
                  const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

