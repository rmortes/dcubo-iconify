import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Similarly to Material Icons, use [Iconify] Widget to display Iconify.
///
/// Heavily inspired by [iconify_flutter](https://github.com/andronasef/iconify_flutter/blob/master/lib/iconify_flutter.dart)
class Iconify extends StatelessWidget {
  /// Creates an Iconify widget.
  const Iconify(
    this.icon, {
    super.key,
    this.color,
    this.size = 24,
  });

  /// The icon to display.
  /// This should be a string of the SVG path data.
  /// Install a companion package to get easy access to selected icons.
  /// Optionally, you can find the path data for an icon on the [Iconify website](https://icon-sets.iconify.design/).
  final String icon;

  /// The color to use when drawing the icon.
  final Color? color;

  /// The size to use when drawing the icon.
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      icon,
      colorFilter:
          color != null ? ColorFilter.mode(color!, BlendMode.srcIn) : null,
      width: size,
      height: size,
    );
  }
}
