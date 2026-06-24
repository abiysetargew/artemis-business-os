import 'package:artemis_business_os/core/i18n/locale_provider.dart';
import 'package:artemis_business_os/core/theme/app_theme.dart';
import 'package:artemis_business_os/core/widgets/app_logo.dart';
import 'package:artemis_business_os/core/widgets/main_shell.dart';
import 'package:artemis_business_os/features/auth/application/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppStrings.of(context);
    final locale = ref.watch(localeProvider);
    final auth = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: const BrandedAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _ProfileHeader(user: auth.user, locale: locale),
          const SizedBox(height: 8),
          _SectionLabel(label: 'Appearance'),
          _SettingsCard(
            children: [
              _Tile(
                icon: Icons.language_rounded,
                iconColor: AppTheme.primaryColor,
                iconBg: AppTheme.primaryLight,
                title: 'Language',
                subtitle: locale.displayName,
                trailing: PopupMenuButton<AppLocale>(
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    color: AppTheme.slate500,
                  ),
                  onSelected: (v) =>
                      ref.read(localeProvider.notifier).setLocale(v),
                  itemBuilder: (_) => AppLocale.values
                      .map(
                        (l) => PopupMenuItem<AppLocale>(
                          value: l,
                          child: Row(
                            children: [
                              Text(
                                l.nativeFlag,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l.displayName,
                                style: TextStyle(
                                  fontWeight: l == locale
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: l == locale
                                      ? AppTheme.primaryColor
                                      : AppTheme.slate900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: s.headingReports),
          _SettingsCard(
            children: [
              _Tile(
                icon: Icons.insights_rounded,
                iconColor: AppTheme.accentColor,
                iconBg: AppTheme.accentColor.withValues(alpha: 0.12),
                title: s.headingReports,
                subtitle: 'Sales, payments, inventory & production',
                onTap: () => context.push('/reports'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionLabel(label: 'Account'),
          _SettingsCard(
            children: [
              _Tile(
                icon: Icons.logout_rounded,
                iconColor: AppTheme.dangerColor,
                iconBg: AppTheme.dangerLight,
                title: 'Sign out',
                subtitle: auth.user?.email ?? '',
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text('You will need to sign in again.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerColor,
                          ),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(authNotifierProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const AppLogo(size: 36),
                const SizedBox(height: 6),
                Text(
                  'Artemis Business OS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate600,
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(fontSize: 11, color: AppTheme.slate500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final dynamic user;
  final AppLocale locale;
  const _ProfileHeader({required this.user, required this.locale});

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? 'Guest';
    final email = user?.email ?? '';
    final role = (user?.role ?? '').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.headerBar,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: Text(
                      role,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppTheme.slate500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        children: List.generate(children.length * 2 - 1, (i) {
          if (i.isOdd) {
            return const Divider(
              height: 1,
              thickness: 1,
              indent: 56,
              color: AppTheme.slate100,
            );
          }
          return children[i ~/ 2];
        }),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onTap != null && trailing == null) ...[
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.slate400,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
