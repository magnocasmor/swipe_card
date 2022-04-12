import 'package:flutter/material.dart';

class SwipeCardItem<T> extends StatefulWidget {
  final T value;
  final Widget child;

  const SwipeCardItem({
    Key? key,
    required this.value,
    required this.child,
  })  : assert(value != null),
        super(key: key);
  _SwipeCardItemState createState() => _SwipeCardItemState<T>();
}

class _SwipeCardItemState<T> extends State<SwipeCardItem<T>> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}