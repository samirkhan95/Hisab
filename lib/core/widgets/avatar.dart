import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hisab/core/constants.dart';

class Avatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const Avatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarChild = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primaryLight,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    } else {
      avatarChild = _buildFallback();
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarChild,
      );
    }
    return avatarChild;
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      child: Icon(
        Icons.person,
        size: radius,
        color: AppColors.primary,
      ),
    );
  }
}
