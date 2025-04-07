import 'package:flutter/material.dart';
import '../../extensions/custom_theme_extension.dart';

class CustomRoundAvatar extends StatelessWidget {
  final ImageProvider<Object>? avatarImage;
  final bool isActive;
  final double radius;
  final double? radiusOfActiveIndicator;

  const CustomRoundAvatar({
    super.key,
    this.avatarImage,
    required this.isActive,
    required this.radius,
    this.radiusOfActiveIndicator = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundImage:
              avatarImage ?? AssetImage('assets/images/avatar.png'),
        ),
        (isActive)
            ? Positioned(
              bottom: 1,
              right: 1,
              child: CircleAvatar(
                backgroundColor: context.theme.bg,
                radius: radiusOfActiveIndicator,
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: context.theme.green,
                ),
              ),
            )
            : Container(),
      ],
    );
  }
}
