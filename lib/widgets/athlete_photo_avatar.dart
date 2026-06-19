import 'package:flutter/material.dart';

class AthletePhotoAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final IconData fallbackIcon;

  const AthletePhotoAvatar({
    super.key,
    required this.photoUrl,
    this.size = 48,
    this.fallbackIcon = Icons.person_outline,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.grey.shade100,
        foregroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
        onForegroundImageError: hasPhoto ? (_, __) {} : null,
        child: Icon(
          fallbackIcon,
          size: size * 0.45,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
