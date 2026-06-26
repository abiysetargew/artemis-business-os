import 'package:flutter/material.dart';

/// Brand logo for Artemis Business OS.
///
/// Renders a gradient indigo→violet rounded badge with bold "AB" initials.
/// Resolution-independent, no asset files, no network calls.
class AppLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final double wordmarkFontSize;

  const AppLogo({
    super.key,
    this.size = 40,
    this.showWordmark = false,
    this.wordmarkFontSize = 18,
  });

  const AppLogo.large({super.key})
    : size = 80,
      showWordmark = true,
      wordmarkFontSize = 26;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'AB',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
          height: 1,
        ),
      ),
    );

    if (!showWordmark) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Artemis',
              style: TextStyle(
                fontSize: wordmarkFontSize,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'BUSINESS OS',
              style: TextStyle(
                fontSize: wordmarkFontSize * 0.4,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8B5CF6),
                letterSpacing: 2.2,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Semantic icon mapping for the app.
class AppIcons {
  AppIcons._();

  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData sales = Icons.point_of_sale_rounded;
  static const IconData customers = Icons.people_alt_rounded;
  static const IconData inventory = Icons.inventory_2_rounded;
  static const IconData products = Icons.category_rounded;
  static const IconData production = Icons.factory_rounded;
  static const IconData payments = Icons.payments_rounded;
  static const IconData reports = Icons.insights_rounded;
  static const IconData users = Icons.manage_accounts_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData notifications = Icons.notifications_rounded;
}
