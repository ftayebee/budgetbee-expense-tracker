import 'package:flutter/material.dart';

const _appLogoAsset = 'lib/assets/images/app_logo.png';
const _appIconAsset = 'lib/assets/images/app_icon.jpg';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 180,
    this.height,
    this.fit = BoxFit.contain,
    this.ensureDarkModeContrast = true,
  });

  final double width;
  final double? height;
  final BoxFit fit;
  final bool ensureDarkModeContrast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final image = Image.asset(
      _appLogoAsset,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: 'BudgetBee',
      errorBuilder: (_, _, _) => Text(
        'BudgetBee',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    if (!ensureDarkModeContrast || theme.brightness != Brightness.dark) {
      return image;
    }

    // The supplied wordmark contains dark lettering. A neutral backdrop keeps
    // the original artwork intact and readable without recoloring or tinting it.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: image,
      ),
    );
  }
}

class AppIconImage extends StatelessWidget {
  const AppIconImage({
    super.key,
    this.size = 80,
    this.borderRadius = 20,
    this.fit = BoxFit.cover,
  });

  final double size;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        _appIconAsset,
        width: size,
        height: size,
        fit: fit,
        semanticLabel: 'BudgetBee app icon',
        errorBuilder: (_, _, _) => ColoredBox(
          color: colors.surfaceContainerHighest,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: size * .5,
              color: colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
