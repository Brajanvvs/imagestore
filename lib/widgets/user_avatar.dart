import 'package:flutter/material.dart';

import '../models/user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 28});

  final User user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF1C1915),
      child: Text(
        user.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.62,
        ),
      ),
    );
  }
}
