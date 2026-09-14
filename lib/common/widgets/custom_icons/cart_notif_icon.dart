import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:supervisormobile/utils/constants/colors.dart';

class TCartCounterIcon extends StatefulWidget {
  const TCartCounterIcon({
    super.key,required this.onPressed, required this.iconColor, this.unreadCount = 0,
  });

  final VoidCallback onPressed;
  final Color iconColor;
  final int unreadCount;

  @override
  State<TCartCounterIcon> createState() => _TCartCounterIconState();
}

class _TCartCounterIconState extends State<TCartCounterIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant TCartCounterIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.unreadCount > oldWidget.unreadCount) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = widget.unreadCount > 0;
    final bellColor = hasUnread ? TColors.warning : widget.iconColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) => Transform.rotate(
            angle: _shakeAnimation.value,
            child: child,
          ),
          child: IconButton(
            onPressed: widget.onPressed,
            icon: Icon(Iconsax.notification, color: bellColor),
          ),
        ),
        if (hasUnread)
          Positioned(
            right: 0,
            top: 4,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                  color: TColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: TColors.white, width: 1.5)
              ),
              child: Center(
                child: Text(
                  widget.unreadCount > 9 ? '9+' : '${widget.unreadCount}',
                  style: Theme.of(context).textTheme.labelLarge!.apply(color:TColors.white,fontSizeFactor: 0.65),
                ),
              ),
            ),
          )
      ],
    );
  }
}
