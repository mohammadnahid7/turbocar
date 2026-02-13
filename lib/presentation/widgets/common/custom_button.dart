import 'package:flutter/material.dart';

enum ButtonType { primary, outline, text, icon }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  // Style Overrides
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.borderSide,
  });

  const CustomButton.outline({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.borderSide,
  }) : type = ButtonType.outline;

  const CustomButton.text({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.borderSide,
  }) : type = ButtonType.text;

  const CustomButton.icon({
    super.key,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.iconSize,
    this.padding,
    this.borderRadius,
    this.borderSide,
  }) : text = '',
       type = ButtonType.icon;

  @override
  Widget build(BuildContext context) {
    final style = _getButtonStyle(context);
    final child = _buildChild();

    Widget button;
    switch (type) {
      case ButtonType.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case ButtonType.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case ButtonType.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
        break;
      case ButtonType.icon:
        // TextButton can be used for icon-only buttons too, or IconButton.
        // User requested "look like a text button, only replacing text with icon".
        // TextButton with Icon child fits well.
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child, // child will be Icon because of _buildChild logic
        );
        break;
    }

    if (width != null || height != null) {
      return SizedBox(
        width: isFullWidth ? double.infinity : width,
        height: height ?? 48,
        child: button,
      );
    }

    if (isFullWidth) {
      return SizedBox(width: double.infinity, height: 48, child: button);
    }

    return SizedBox(height: 48, child: button);
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: foregroundColor,
        ),
      );
    }

    if (icon != null) {
      if (type == ButtonType.icon) {
        return Icon(icon, size: iconSize ?? 24);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize ?? 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
    );

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: shape,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          side: borderSide,
        );
      case ButtonType.outline:
        return OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.primary,
          side:
              borderSide ??
              BorderSide(color: Theme.of(context).colorScheme.primary),
          shape: shape,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        );
      case ButtonType.text:
        return TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.primary,
          shape: shape,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          side: borderSide,
        );
      case ButtonType.icon:
        return TextButton.styleFrom(
          foregroundColor:
              foregroundColor ?? Theme.of(context).colorScheme.onSurface,
          backgroundColor:
              backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
          shape: borderRadius != null
              ? RoundedRectangleBorder(borderRadius: borderRadius!)
              : const CircleBorder(),
          padding: padding ?? const EdgeInsets.all(12),
          side: borderSide ?? BorderSide(color: Theme.of(context).dividerColor),
        );
    }
  }
}
