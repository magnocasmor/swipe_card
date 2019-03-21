import 'package:flutter/material.dart';
import 'package:swipe_card/src/swipe_card_animation_metrics.dart';
import 'package:swipe_card/swipe_card.dart';

class SwipeCardController<T> {
  SwipeCardAnimationMetrics _metrics;
  GlobalKey<State<SwipeCardStack>> _swiperStateKey;
  List<SwipeCardItem> _children;
  SwipeCardItem _currentCard;
  final Function(T) onAccepted;
  final Function(T) onRejected;
  final VoidCallback onCompleted;

  SwipeCardController({this.onAccepted, this.onRejected, this.onCompleted});

  void initController(GlobalKey<State<SwipeCardStack>> key,
      SwipeCardAnimationMetrics metrics, List<SwipeCardItem> children) {
    this._swiperStateKey = key;
    this._metrics = metrics;
    this._children = children;
  }

  set currentCard(SwipeCardItem currentCard) => _currentCard = currentCard;

  void acceptCard() {
    _metrics.initCardAnimationParameters();
    _metrics.animateDeck(SwipeCardAnimate.REVERSE);
    _metrics.animateCardSwipe(Offset(1000.0, -100), (status) {
      if (status == AnimationStatus.completed) {
        onAccepted(_currentCard.value);
        removeCardAndUpdateDeck();
      }
    }, () {
      _swiperStateKey.currentState.setState(() {
        _metrics.updateCardPositionAndRotate();
      });
    });
  }

  void rejectCard() {
    _metrics.initCardAnimationParameters();
    _metrics.animateDeck(SwipeCardAnimate.REVERSE);
    _metrics.animateCardSwipe(Offset(-1000.0, -100), (status) {
      if (status == AnimationStatus.completed) {
        onRejected(_currentCard.value);
        removeCardAndUpdateDeck();
      }
    }, () {
      _swiperStateKey.currentState.setState(() {
        _metrics.updateCardPositionAndRotate();
      });
    });
  }

  void removeCardAndUpdateDeck() {
    _swiperStateKey.currentState.setState(() {
      _children.remove(_currentCard);
      _currentCard = null;
      onCompleted();
      _metrics.animateDeck(SwipeCardAnimate.FORWARD, from: 1.0);
      _metrics.initCardAnimationParameters();
    });
  }
}
