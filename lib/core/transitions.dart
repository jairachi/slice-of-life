import 'package:flutter/material.dart';

/// Dialog that slides in from the left and out to the right (the dark backdrop fades).
Future<T?> showFade<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) => showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (ctx, _, __) => builder(ctx),
      // Slide in from the left, slide out to the right.
      transitionBuilder: (ctx, anim, _, child) {
        final width = MediaQuery.of(ctx).size.width;
        return AnimatedBuilder(
          animation: anim,
          child: child,
          builder: (_, child) {
            final leaving = anim.status == AnimationStatus.reverse;
            // entering: ease-out from -width to 0; leaving: ease-in from 0 to +width
            final dx = leaving ? Curves.easeInCubic.transform(1 - anim.value) * width : -(1 - Curves.easeOutCubic.transform(anim.value)) * width;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
        );
      },
    );
