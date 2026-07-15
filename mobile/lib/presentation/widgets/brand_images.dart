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

    return image;
  }
}

enum BrandSize { compact, standard, large }

class BudgetBeeBrand extends StatelessWidget {
  const BudgetBeeBrand({
    super.key,
    this.size = BrandSize.standard,
    this.showSlogan = true,
    this.centered = false,
  });

  final BrandSize size;
  final bool showSlogan;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final iconSize = switch (size) {
      BrandSize.compact => 38.0,
      BrandSize.standard => 46.0,
      BrandSize.large => 64.0,
    };
    final titleSize = switch (size) {
      BrandSize.compact => 20.0,
      BrandSize.standard => 23.0,
      BrandSize.large => 31.0,
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconImage(size: iconSize, borderRadius: iconSize * .28),
        const SizedBox(width: 11),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Budget',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(
                    text: 'Bee',
                    style: TextStyle(color: Color(0xFFF59E0B)),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
            if (showSlogan)
              Text(
                'Track. Save. Grow.',
                style: TextStyle(
                  fontSize: titleSize * .43,
                  letterSpacing: .7,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
    return centered ? Center(child: content) : content;
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
