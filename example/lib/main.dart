import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:swipe_card/swipe_card.dart';

final swipeController = SwipeCardController<int>();

void main() {
  // timeDilation = 5.0;
  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Swipe Card Example'),
        ),
        body: SwipeCardExample(),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.check),
          onPressed: () {
            swipeController.completeSwipe(
              accepteds: [0, 1, 2],
              rejecteds: [3, 4, 5],
            );
          },
        ),
      ),
    );
  }
}

class SwipeCardExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SwipeCardStack<int>(
        swipeController: swipeController,
        deckPadding: const EdgeInsets.symmetric(horizontal: 32.0),
        children: List<SwipeCardItem<int>>.generate(
          6,
          (int index) => SwipeCardItem<int>(
            value: index,
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(
                        'https://picsum.photos/id/${math.Random().nextInt(1000)}/200/200'),
                  ),
                ),
              ),
            ),
          ),
        ),
        completedWidget: AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: Colors.grey,
            child: Center(
                child: Text('Clique em alguma imagem se quiser corrigir')),
          ),
        ),
        rejectButton: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FlatButton(
            padding: EdgeInsets.all(24.0),
            shape: CircleBorder(),
            color: Colors.red,
            child: Icon(
              Icons.clear,
              color: Colors.red,
            ),
            onPressed: swipeController.rejectCard,
          ),
        ),
        acceptButton: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FlatButton(
            padding: EdgeInsets.all(24.0),
            shape: CircleBorder(),
            color: Colors.green,
            child: Icon(
              Icons.check,
            ),
            onPressed: swipeController.acceptCard,
          ),
        ),
        onAccepted: (int value) {
          print('Accepted card value = $value');
        },
        onRejected: (int value) {
          print('Rejected card value = $value');
        },
        onReview: (int value) {
          print('Review card value = $value');
        },
        onCompleted: () {
          print('Swipe Completed');
        },
        correctIndicator: Icon(
          Icons.person,
          color: Colors.green,
          size: 48.0,
        ),
        incorrectIndicator: Icon(
          Icons.remove_circle,
          color: Colors.red,
          size: 48.0,
        ),
      ),
    );
  }
}
