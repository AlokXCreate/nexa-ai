import 'package:flutter/material.dart';
import 'package:localmind_ai/core/widgets/glass_container.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 0,
      blur: 20,
      color: Colors.black.withOpacity(0.5),
      borderColor: Colors.transparent,
      child: SafeArea(
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: NavigationToolbar(
            leading: leading,
            middle: title,
            trailing: actions != null ? Row(mainAxisSize: MainAxisSize.min, children: actions!) : null,
            centerMiddle: true,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
