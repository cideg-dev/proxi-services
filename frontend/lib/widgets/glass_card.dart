import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}