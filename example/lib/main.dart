import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:swipe_card/swipe_card.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Swipe Card Example'),
        ),
        body: SwipeCardExample(),
      ),
    );
  }
}

class SwipeCardExample extends StatelessWidget {
  final swipeController = SwipeCardController<int>(
    onAccepted: (int value) {
      print('Accepted card value = $value');
    },
    onRejected: (int value) {
      print('rejected card value = $value');
    },
    onCompleted: () {
      print('Swipe Completed');
    },
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Expanded(
          flex: 8,
          child: SwipeCardStack<int>(
            swipeCardController: swipeController,
            children: List<SwipeCardItem<int>>.generate(
              10,
              (int index) => SwipeCardItem<int>(
                    value: index,
                    child: Container(
                        color: Color(
                                (math.Random().nextDouble() * 255 * 0xFFFFFF)
                                        .toInt() <<
                                    0)
                            .withOpacity(1.0)),
                  ),
            ),
          ),
        ),
        Flexible(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                onPressed: () {
                  swipeController.acceptCard();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.red,
                ),
                onPressed: () {
                  swipeController.rejectCard();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
