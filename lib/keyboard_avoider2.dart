import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class KeyboardAvoider extends StatefulWidget {
  final Widget child;
  final double maxPadding;
  final Duration duration;

  const KeyboardAvoider(
      {required this.child,
      this.duration = const Duration(milliseconds: 300),
      double? maxPadding,
      super.key})
      : maxPadding = maxPadding ?? double.infinity;

  @override
  State<KeyboardAvoider> createState() => _KeyboardAvoiderState();
}

class _KeyboardAvoiderState extends State<KeyboardAvoider> with SingleTickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();
  late final AnimationController _controller;
  late Animation<double> _paddingAnimation;

  double _currentPadding = 0;
  double _keyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _paddingAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _adjustPadding() {
    final renderBox = _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewInsets = MediaQuery.of(context).viewInsets;
    if (viewInsets.bottom != _keyboardHeight) _keyboardHeight = viewInsets.bottom;

    final childBottom = renderBox.localToGlobal(Offset.zero).dy + renderBox.size.height;
    final keyboardTop = MediaQuery.of(context).size.height - _keyboardHeight;
    final overlap = childBottom - keyboardTop;

    final newPadding = overlap > 0 ? overlap : 0.0;
    if (newPadding == _currentPadding) return;

    setState(() => _currentPadding = newPadding);
    _paddingAnimation = Tween<double>(
      begin: _paddingAnimation.value,
      end: newPadding,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    // Schedule adjustment after frame renders
    SchedulerBinding.instance.addPostFrameCallback((_) => _adjustPadding());

    return AnimatedBuilder(
      animation: _paddingAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.max(-_paddingAnimation.value, -widget.maxPadding)),
        child: child,
      ),
      child: KeyedSubtree(key: _childKey, child: widget.child),
    );
  }
}
