import 'package:flutter/material.dart';
import 'package:swipe_card/src/swipe_card_animation_metrics.dart';
import 'package:swipe_card/src/swipe_card_controller.dart';
import 'package:swipe_card/src/swipe_card_item.dart';

final _key = GlobalKey<State<SwipeCardStack>>();

class SwipeCardStack<T> extends StatefulWidget {
  final double height;
  final double width;
  final Color backgroundColor;
  final List<SwipeCardItem> children;
  final SwipeCardController<T> swipeController;

  SwipeCardStack({
    this.height,
    this.width,
    this.backgroundColor,
    this.children = const <SwipeCardItem>[],
    SwipeCardController swipeCardController,
  })  : assert(children != null),
        this.swipeController = swipeCardController ?? SwipeCardController<T>(),
        super(key: _key);

  _SwipeCardStackState createState() => _SwipeCardStackState<T>();
}

class _SwipeCardStackState<T> extends State<SwipeCardStack<T>>
    with TickerProviderStateMixin {
  final _stackKey = GlobalKey();
  SwipeCardAnimationMetrics _metrics;

  void initState() {
    super.initState();
    _metrics = SwipeCardAnimationMetrics(this);
    widget.swipeController.initController(_key, _metrics, widget.children);
    _metrics.initCardAnimationParameters();
    _metrics.animateDeck(SwipeCardAnimate.FORWARD);
  }

  @override
  Widget build(BuildContext context) {
    _metrics.initDeckAnimationParameters();
    return Container(
      height: widget.height,
      width: widget.width,
      color:
          widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              overflow: Overflow.visible,
              fit: StackFit.expand,
              key: _stackKey,
              children: widget.children.reversed
                  .map(
                    (swiperCard) {
                      return swiperCard == widget.children.last
                          ? _buildTopCard(
                              widget.swipeController.currentCard = swiperCard)
                          : _buildHideCard(swiperCard);
                    },
                  )
                  .toList()
                  .reversed
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _metrics.animationsDispose();
    super.dispose();
  }

  void _onAcceptedCard(SwipeCardItem swiperCard) {
    widget.swipeController.onAccepted(swiperCard.value);
    widget.swipeController.removeCardAndUpdateDeck();
  }

  void _onRejectedCard(SwipeCardItem swiperCard) {
    widget.swipeController.onRejected(swiperCard.value);
    widget.swipeController.removeCardAndUpdateDeck();
  }

  Widget _buildHideCard(SwipeCardItem swiperCard) {
    return SlideTransition(
      position: _metrics.deckAnimatedPosition(),
      child: ScaleTransition(
        scale: _metrics.deckAnimatedScale(),
        child: _createContentCard(
          swiperCard,
        ),
      ),
    );
  }

  Widget _buildTopCard(SwipeCardItem child) {
    widget.swipeController.currentCard = child;
    return Transform.translate(
      offset: _metrics.currentCardPosition,
      child: Transform.rotate(
        angle: _metrics.cardAngle,
        child: _createGestureCard(child),
      ),
    );
  }

  Widget _createContentCard(SwipeCardItem swiperCard) => Container(
        width: widget.width,
        height: widget.height,
        child: swiperCard,
      );

  Widget _createGestureCard(SwipeCardItem swiperCard) => GestureDetector(
        onPanStart: (DragStartDetails _) {
          _metrics.animateDeck(SwipeCardAnimate.REVERSE);
        },
        onPanUpdate: (DragUpdateDetails details) {
          _metrics.resetCardAnimation();
          setState(() {
            _metrics.updateCardPositionAndRotate(delta: details.delta);
          });
        },
        onPanEnd: (DragEndDetails details) {
          final cardRenderBox =
              _stackKey.currentContext.findRenderObject() as RenderBox;
          final cardSize = cardRenderBox.size;
          final listener = () {
            setState(() {
              _metrics.updateCardPositionAndRotate();
            });
          };
          if (_metrics.isCardInsideEdges(cardSize.width)) {
            _metrics.animateCardReturn(listener);
          } else {
            _metrics.animateCardSwipe(details.velocity.pixelsPerSecond,
                (status) {
              if (status == AnimationStatus.completed) {
                if (_metrics.currentCardPosition.dx > 0)
                  _onAcceptedCard(swiperCard);
                else
                  _onRejectedCard(swiperCard);
              }
            }, listener);
          }
        },
        child: _createContentCard(swiperCard),
      );
}

// enum SwipeCardAnimate { FORWARD, REVERSE }

// class SwipeCardAnimationMetrics {
//   AnimationController _cardAnimationController;
//   AnimationController _deckAnimationController;
//   Animation<Offset> _cardAnimation;
//   Offset _currentCardPosition;
//   Offset _deckPosition;
//   double _cardAngle;
//   double _deckScale;
//   final TickerProvider _swiperCardState;

//   SwipeCardAnimationMetrics(this._swiperCardState);

//   Offset get currentCardPosition => _currentCardPosition;

//   double get cardAngle => _cardAngle;

//   void initCardAnimationParameters() {
//     _currentCardPosition = Offset.zero;
//     _cardAngle = 0.0;
//   }

//   void initDeckAnimationParameters() {
//     _deckPosition = Offset.zero;
//     _deckScale = 1.0;
//   }

//   void initDeckAnimation() {
//     initDeckAnimationParameters();
//     _deckAnimationController = AnimationController(
//       duration: Duration(milliseconds: 500),
//       vsync: _swiperCardState,
//     );
//   }

//   void animateDeck(SwipeCardAnimate animate, {double from}) {
//     if (_deckAnimationController == null) initDeckAnimation();
//     if (animate == SwipeCardAnimate.FORWARD)
//       _deckAnimationController.forward(from: from);
//     else
//       _deckAnimationController.reverse(from: from);
//   }

//   double _calcAngle(Offset pos) => _cardAngle = pos.dx * 0.003;

//   Offset _calcPosition(Offset currentPosition, Offset delta) =>
//       _currentCardPosition =
//           Offset(currentPosition.dx + delta.dx, currentPosition.dy + delta.dy);

//   void animationsDispose() {
//     if (_cardAnimationController?.status == AnimationStatus.forward ||
//         _cardAnimationController?.status == AnimationStatus.reverse)
//       _cardAnimationController.reset();
//     _cardAnimationController?.dispose();
//     if (_deckAnimationController?.status == AnimationStatus.forward ||
//         _deckAnimationController?.status == AnimationStatus.reverse)
//       _deckAnimationController.reset();
//     _deckAnimationController?.dispose();
//   }

//   Animation<Offset> deckAnimatedPosition() {
//     return Tween<Offset>(
//       begin: _deckPosition,
//       end: _deckPosition.dy > -.25
//           ? _deckPosition = _deckPosition.translate(.0, -.05)
//           : _deckPosition,
//     ).animate(_deckAnimationController);
//   }

//   Animation<double> deckAnimatedScale() {
//     return Tween<double>(
//       begin: _deckScale,
//       end: _deckScale -= .085,
//     ).animate(_deckAnimationController);
//   }

//   void resetCardAnimation() {
//     if (_cardAnimationController?.status == AnimationStatus.forward) {
//       _cardAnimationController.reset();
//       initCardAnimationParameters();
//     }
//   }

//   bool isCardInsideEdges(double cardWidth) {
//     return _currentCardPosition.dx < 0.4 * cardWidth &&
//         _currentCardPosition.dx > -0.4 * cardWidth;
//   }

//   void animateCardSwipe(
//       Offset targetOffset, Function statusListener, VoidCallback listener) {
//     final targetPosition = _currentCardPosition.translate(
//         2 * _currentCardPosition.dx + targetOffset.dx,
//         2 * _currentCardPosition.dy +
//             targetOffset.dy); //details.velocity.pixelsPerSecond;
//     _initCardAnimation(500, targetPosition, Curves.linear);
//     _cardAnimation.addStatusListener(statusListener);
//     _cardAnimation.addListener(listener);
//     _cardAnimationController.forward();
//   }

//   void _initCardAnimation(int milliseconds, Offset endOffset, Curve curve) {
//     _cardAnimationController = AnimationController(
//       duration: Duration(milliseconds: milliseconds),
//       vsync: _swiperCardState,
//     );
//     _cardAnimation = Tween<Offset>(
//       begin: _currentCardPosition,
//       end: endOffset,
//     ).animate(
//       CurvedAnimation(
//         parent: _cardAnimationController,
//         curve: curve,
//       ),
//     );
//   }

//   void animateCardReturn(VoidCallback listener) {
//     _initCardAnimation(1000, Offset.zero, Curves.elasticOut);
//     initDeckAnimation();
//     _deckAnimationController.forward();
//     _cardAnimation.addListener(listener);
//     _cardAnimationController.forward();
//   }

//   void updateCardPositionAndRotate({Offset delta}) {
//     delta != null
//         ? _calcPosition(_currentCardPosition, delta)
//         : _currentCardPosition = _cardAnimation.value;
//     _calcAngle(_currentCardPosition);
//   }
// }
