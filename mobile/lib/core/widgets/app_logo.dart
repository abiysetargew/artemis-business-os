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

/// Brand-consistent shadow tokens for cards, sheets, and elevated surfaces.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(color: Color(0x4D6366F1), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

/// Semantic brand gradients.
class AppGradients {
  AppGradients._();

  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  static const LinearGradient headerBar = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
  );

  static const LinearGradient success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  static const LinearGradient warning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
  );

  static const LinearGradient danger = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
  );
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
