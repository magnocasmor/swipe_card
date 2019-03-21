import 'package:flutter/material.dart';

enum SwipeCardAnimate { FORWARD, REVERSE }

class SwipeCardAnimationMetrics {
  AnimationController _cardAnimationController;
  AnimationController _deckAnimationController;
  Animation<Offset> _cardAnimation;
  Offset _currentCardPosition;
  Offset _deckPosition;
  double _cardAngle;
  double _deckScale;
  final TickerProvider _swiperCardState;

  SwipeCardAnimationMetrics(this._swiperCardState);

  Offset get currentCardPosition => _currentCardPosition;

  double get cardAngle => _cardAngle;

  void initCardAnimationParameters() {
    _currentCardPosition = Offset.zero;
    _cardAngle = 0.0;
  }

  void initDeckAnimationParameters() {
    _deckPosition = Offset.zero;
    _deckScale = 1.0;
  }

  void initDeckAnimation() {
    initDeckAnimationParameters();
    _deckAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: _swiperCardState,
    );
  }

  void animateDeck(SwipeCardAnimate animate, {double from}) {
    if (_deckAnimationController == null) initDeckAnimation();
    if (animate == SwipeCardAnimate.FORWARD)
      _deckAnimationController.forward(from: from);
    else
      _deckAnimationController.reverse(from: from);
  }

  double _calcAngle(Offset pos) => _cardAngle = pos.dx * 0.003;

  Offset _calcPosition(Offset currentPosition, Offset delta) =>
      _currentCardPosition =
          Offset(currentPosition.dx + delta.dx, currentPosition.dy + delta.dy);

  void animationsDispose() {
    if (_cardAnimationController?.status == AnimationStatus.forward ||
        _cardAnimationController?.status == AnimationStatus.reverse)
      _cardAnimationController.reset();
    _cardAnimationController?.dispose();
    if (_deckAnimationController?.status == AnimationStatus.forward ||
        _deckAnimationController?.status == AnimationStatus.reverse)
      _deckAnimationController.reset();
    _deckAnimationController?.dispose();
  }

  Animation<Offset> deckAnimatedPosition() {
    return Tween<Offset>(
      begin: _deckPosition,
      end: _deckPosition.dy > -.25
          ? _deckPosition = _deckPosition.translate(.0, -.05)
          : _deckPosition,
    ).animate(_deckAnimationController);
  }

  Animation<double> deckAnimatedScale() {
    return Tween<double>(
      begin: _deckScale,
      end: _deckScale -= .085,
    ).animate(_deckAnimationController);
  }

  void resetCardAnimation() {
    if (_cardAnimationController?.status == AnimationStatus.forward) {
      _cardAnimationController.reset();
      initCardAnimationParameters();
    }
  }

  bool isCardInsideEdges(double cardWidth) {
    return _currentCardPosition.dx < 0.4 * cardWidth &&
        _currentCardPosition.dx > -0.4 * cardWidth;
  }

  void animateCardSwipe(
      Offset targetOffset, Function statusListener, VoidCallback listener) {
        
    final targetPosition = _currentCardPosition.translate(
        2 * _currentCardPosition.dx + targetOffset.dx,
        2 * _currentCardPosition.dy +
            targetOffset.dy); //details.velocity.pixelsPerSecond;
    _initCardAnimation(500, targetPosition, Curves.linear);
    _cardAnimation.addStatusListener(statusListener);
    _cardAnimation.addListener(listener);
    _cardAnimationController.forward();
  }

  void _initCardAnimation(int milliseconds, Offset endOffset, Curve curve) {
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: milliseconds),
      vsync: _swiperCardState,
    );
    _cardAnimation = Tween<Offset>(
      begin: _currentCardPosition,
      end: endOffset,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: curve,
      ),
    );
  }

  void animateCardReturn(VoidCallback listener) {
    _initCardAnimation(1000, Offset.zero, Curves.elasticOut);
    initDeckAnimation();
    _deckAnimationController.forward();
    _cardAnimation.addListener(listener);
    _cardAnimationController.forward();
  }

  void updateCardPositionAndRotate({Offset delta}) {
    delta != null
        ? _calcPosition(_currentCardPosition, delta)
        : _currentCardPosition = _cardAnimation.value;
    _calcAngle(_currentCardPosition);
  }
}
