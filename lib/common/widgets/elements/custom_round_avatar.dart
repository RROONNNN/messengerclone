import 'package:flutter/material.dart';
import '../../extensions/custom_theme_extension.dart';

class CustomRoundAvatar extends StatelessWidget {
  final ImageProvider<Object>? avatarImage;
  final bool isActive;
  final double radius;

  const CustomRoundAvatar({
    super.key,
    this.avatarImage,
    required this.isActive,
    required this.radius,
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
                radius: 8,
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
