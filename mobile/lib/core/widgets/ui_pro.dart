import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================================
// GLASS CARD
// ============================================================================

/// A frosted-glass card with optional accent top border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? accentColor;
  final bool elevated;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = AppTheme.radiusLg,
    this.accentColor,
    this.elevated = true,
    this.onTap,
    this.onLongPress,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppTheme.durBase,
      curve: AppTheme.curveSpring,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppTheme.slate200, width: 1),
        boxShadow: elevated ? AppTheme.elevationSm : null,
      ),
      child: Stack(
        children: [
          if (accentColor != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(radius),
                  ),
                ),
              ),
            ),
          Padding(
            padding: padding ?? const EdgeInsets.all(AppTheme.s4),
            child: child,
          ),
        ],
      ),
    );

    if (onTap == null && onLongPress == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

// ============================================================================
// ANIMATED KPI TILE
// ============================================================================

class AnimatedKPI extends StatefulWidget {
  final String label;
  final num value;
  final String? prefix;
  final String? suffix;
  final IconData icon;
  final Color color;
  final List<num>? sparklineData;
  final num? previousValue;
  final String? trendLabel;
  final bool compact;
  final VoidCallback? onTap;

  const AnimatedKPI({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.prefix,
    this.suffix,
    this.sparklineData,
    this.previousValue,
    this.trendLabel,
    this.compact = false,
    this.onTap,
  });

  @override
  State<AnimatedKPI> createState() => _AnimatedKPIState();
}

class _AnimatedKPIState extends State<AnimatedKPI>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _displayed = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.curveSpring),
    );
    _controller.forward();
    _animation.addListener(() {
      if (mounted) {
        setState(() => _displayed = (widget.value * _animation.value).round());
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedKPI old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delta = widget.previousValue != null
        ? (widget.value - widget.previousValue!).toDouble()
        : null;
    final deltaPercent =
        (widget.previousValue != null && widget.previousValue != 0)
        ? (delta! / widget.previousValue!.toDouble() * 100)
        : null;

    final tile = GlassCard(
      accentColor: widget.color,
      padding: EdgeInsets.all(widget.compact ? AppTheme.s4 : AppTheme.s5),
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: widget.compact ? 36 : 44,
                height: widget.compact ? 36 : 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color.withValues(alpha: 0.18),
                      widget.color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: widget.compact ? 18 : 22,
                ),
              ),
              const Spacer(),
              if (deltaPercent != null)
                _TrendBadge(percent: deltaPercent, color: widget.color),
            ],
          ),
          SizedBox(height: widget.compact ? AppTheme.s3 : AppTheme.s4),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.compact ? 11 : 12,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              if (widget.prefix != null) ...[
                Text(
                  widget.prefix!,
                  style: TextStyle(
                    fontSize: widget.compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
              Flexible(
                child: Text(
                  _formatNumber(_displayed),
                  style: TextStyle(
                    fontSize: widget.compact ? 20 : 26,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.slate900,
                    letterSpacing: -0.6,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.suffix != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.suffix!,
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (widget.sparklineData != null &&
              widget.sparklineData!.length > 1) ...[
            const SizedBox(height: AppTheme.s3),
            SizedBox(
              height: 36,
              child: Sparkline(
                data: widget.sparklineData!,
                color: widget.color,
              ),
            ),
          ],
        ],
      ),
    );

    return tile;
  }

  String _formatNumber(num n) {
    if (n.abs() >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n.abs() >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toStringAsFixed(0);
  }
}

class _TrendBadge extends StatelessWidget {
  final double percent;
  final Color color;
  const _TrendBadge({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final isUp = percent >= 0;
    final c = isUp ? AppTheme.successColor : AppTheme.dangerColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            color: c,
            size: 11,
          ),
          const SizedBox(width: 2),
          Text(
            '${isUp ? '+' : ''}${percent.toStringAsFixed(0)}%',
            style: TextStyle(
              color: c,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SPARKLINE
// ============================================================================

class Sparkline extends StatelessWidget {
  final List<num> data;
  final Color color;
  final double height;
  final bool fill;

  const Sparkline({
    super.key,
    required this.data,
    required this.color,
    this.height = 40,
    this.fill = true,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) {
      return SizedBox(height: height);
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: color, fill: fill),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<num> data;
  final Color color;
  final bool fill;

  _SparklinePainter({
    required this.data,
    required this.color,
    required this.fill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxV = data.reduce(math.max).toDouble();
    final minV = data.reduce(math.min).toDouble();
    final range = (maxV - minV).abs();
    final stepX = size.width / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalized = range == 0 ? 0.5 : (data[i].toDouble() - minV) / range;
      final y = size.height - (normalized * (size.height - 4)) - 2;
      points.add(Offset(x, y));
    }

    if (fill) {
      final fillPath = Path()
        ..moveTo(0, size.height)
        ..lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath
        ..lineTo(size.width, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, prev.dy);
      linePath.quadraticBezierTo(mid.dx, mid.dy, curr.dx, curr.dy);
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Last point dot
    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 2.5, dotPaint);
    canvas.drawCircle(
      points.last,
      5,
      Paint()
        ..color = color.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.data != data || old.color != color;
}

// ============================================================================
// SKELETON SHIMMER
// ============================================================================

class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppTheme.radiusXs,
    this.circle = false,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.circle
                ? BorderRadius.circular(widget.height / 2)
                : BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, 0),
              end: Alignment(1 + t * 2, 0),
              colors: const [
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// EMPTY STATE WITH ILLUSTRATION
// ============================================================================

class EmptyStatePro extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;

  const EmptyStatePro({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative illustration
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.18),
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor.withValues(alpha: 0.08),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 44, color: accentColor),
                  ),
                  // Floating dots
                  Positioned(
                    top: 20,
                    right: 18,
                    child: _FloatDot(color: AppTheme.cyanColor, size: 8),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 16,
                    child: _FloatDot(color: AppTheme.accentColor, size: 6),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 24,
                    child: _FloatDot(color: AppTheme.warningColor, size: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.s6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate900,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.s2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.slate500,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.s6),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.s5,
                    vertical: AppTheme.s3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FloatDot extends StatefulWidget {
  final Color color;
  final double size;
  const _FloatDot({required this.color, required this.size});

  @override
  State<_FloatDot> createState() => _FloatDotState();
}

class _FloatDotState extends State<_FloatDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, -math.sin(_ctrl.value * math.pi) * 4),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.7),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// SECTION HEADER
// ============================================================================

class SectionHeaderPro extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final Color accentColor;

  const SectionHeaderPro({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.accentColor = AppTheme.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.slate900,
                    letterSpacing: -0.2,
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
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS PILL (modern replacement for badges)
// ============================================================================

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool small;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final pad = small ? 6.0 : 8.0;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: pad + 2,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: small ? 5 : 6,
            height: small ? 5 : 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, color: color, size: small ? 10 : 12),
          ],
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMMAND PALETTE (Cmd+K)
// ============================================================================

class CommandPalette extends StatefulWidget {
  final Future<List<CommandItem>> Function(String query) onSearch;
  final void Function(CommandItem item) onSelect;

  const CommandPalette({
    super.key,
    required this.onSearch,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<List<CommandItem>> Function(String) onSearch,
    required void Function(CommandItem) onSelect,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: AppTheme.durBase,
      pageBuilder: (ctx, anim, secAnim) {
        return CommandPalette(onSearch: onSearch, onSelect: onSelect);
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(
              CurvedAnimation(parent: anim, curve: AppTheme.curveSpring),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class CommandItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String category;
  final Color? color;

  CommandItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.category,
    this.color,
  });
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<CommandItem> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _runSearch('');
  }

  Future<void> _runSearch(String q) async {
    setState(() => _loading = true);
    final results = await widget.onSearch(q);
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.elevationXl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _runSearch,
                      decoration: InputDecoration(
                        hintText:
                            'Search anything... (customers, products, sales)',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.slate100,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
                          ),
                          child: const Text(
                            'ESC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          )
                        : _results.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              'No results',
                              style: TextStyle(
                                color: AppTheme.slate500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) {
                              final item = _results[i];
                              return ListTile(
                                leading: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: (item.color ?? AppTheme.primaryColor)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 16,
                                    color: item.color ?? AppTheme.primaryColor,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: item.subtitle != null
                                    ? Text(
                                        item.subtitle!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.slate500,
                                        ),
                                      )
                                    : null,
                                trailing: Text(
                                  item.category,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.slate400,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  widget.onSelect(item);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BENTO GRID (mixed-size layout)
// ============================================================================

class BentoCell extends StatelessWidget {
  final Widget child;
  final int cols;
  final int rows;
  final Color? backgroundColor;
  final Color? accentColor;

  const BentoCell({
    super.key,
    required this.child,
    this.cols = 1,
    this.rows = 1,
    this.backgroundColor,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: AppTheme.elevationXs,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Stack(
          children: [
            if (accentColor != null)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// GLOW ICON (icon with colored glow)
// ============================================================================

class GlowIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double glowSize;

  const GlowIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.glowSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + glowSize,
      height: size + glowSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.0)],
        ),
      ),
      child: Icon(icon, color: color, size: size),
    );
  }
}

// ============================================================================
// HERO HEADER (gradient with glow)
// ============================================================================

class HeroHeader extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final double height;
  final EdgeInsetsGeometry padding;
  final bool glow;

  const HeroHeader({
    super.key,
    required this.child,
    this.gradient = AppTheme.gradientHeader,
    this.height = 180,
    this.padding = const EdgeInsets.fromLTRB(20, 24, 20, 24),
    this.glow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: glow
            ? AppTheme.glow(gradient.colors.first, intensity: 0.3)
            : null,
      ),
      child: Stack(
        children: [
          if (glow) ...[
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

// ============================================================================
// ANIMATED NUMBER (slot-machine counter)
// ============================================================================

class AnimatedNumber extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final Duration duration;
  final int decimals;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.duration = const Duration(milliseconds: 1400),
    this.decimals = 0,
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _current = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppTheme.curveSpring));
    _anim.addListener(() {
      if (mounted) setState(() => _current = _anim.value);
    });
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedNumber old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _anim = Tween<double>(
        begin: _current,
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _ctrl, curve: AppTheme.curveSpring));
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${widget.prefix ?? ''}${_current.toStringAsFixed(widget.decimals)}${widget.suffix ?? ''}',
      style: widget.style,
    );
  }
}
