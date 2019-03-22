import 'package:flutter/material.dart';
import 'package:swipe_card/src/swipe_card_animation_metrics.dart';
import 'package:swipe_card/src/swipe_card_controller.dart';
import 'package:swipe_card/src/swipe_card_item.dart';

final _key = GlobalKey<State<SwipeCardStack>>();

class SwipeCardStack<T> extends StatefulWidget {
  final double height;
  final double width;
  final Color backgroundColor;
  final SwipeCardController<T> swipeController;
  final List<SwipeCardItem> children;
  final Widget correctIndicator;
  final Widget incorrectIndicator;

  SwipeCardStack({
    this.height,
    this.width,
    this.backgroundColor,
    this.children = const <SwipeCardItem>[],
    SwipeCardController swipeCardController,
    this.correctIndicator,
    this.incorrectIndicator,
  })  : assert(children != null),
        this.swipeController = swipeCardController ?? SwipeCardController<T>(),
        super(key: _key);

  _SwipeCardStackState createState() => _SwipeCardStackState<T>();
}

class _SwipeCardStackState<T> extends State<SwipeCardStack<T>>
    with TickerProviderStateMixin {
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
              children: widget.children.reversed
                  .map(
                    (swiperCard) {
                      return swiperCard == widget.children.last
                          ? _buildCard(
                              widget.swipeController.currentCard = swiperCard)
                          : _buildDeck(swiperCard);
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

  Widget _buildDeck(SwipeCardItem swiperCard) {
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

  Widget _buildCard(SwipeCardItem child) {
    widget.swipeController.currentCard = child;
    return Transform.translate(
      offset: _metrics.currentCardPosition,
      child: Transform.rotate(
        angle: _metrics.cardAngle,
        child: _createGestureCard(child),
      ),
    );
  }

  double _calcOpacity() {
    double opacity = (_metrics.currentCardPosition.dx * .01).abs();
    if (opacity >= 1.0) opacity = 1.0;
    return opacity;
  }

  Widget _createContentCard(SwipeCardItem swiperCard) {
    return Container(
      width: widget.width,
      height: widget.height,
      child: swiperCard,
    );
  }

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
              _key.currentContext.findRenderObject() as RenderBox;
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
        child: Stack(
          children: <Widget>[
            _createContentCard(swiperCard),
            Positioned(
              top: widget.height != null ? widget.height * .03 : 30.0,
              left: widget.width != null ? widget.width * .03 : 30.0,
              child: Opacity(
                opacity: (_metrics.currentCardPosition.dx >
                        (widget.width != null ? widget.width * 0.3 : 50))
                    ? _calcOpacity()
                    : 0.0,
                child: widget.correctIndicator,
              ),
            ),
            Positioned(
              top: widget.height != null ? widget.height * .03 : 30.0,
              right: widget.width != null ? widget.width * .03 : 30.0,
              child: Opacity(
                opacity: (_metrics.currentCardPosition.dx <
                        (widget.width != null ? -widget.width * 0.3 : -50))
                    ? _calcOpacity()
                    : 0.0,
                child: widget.incorrectIndicator,
              ),
            ),
          ],
        ),
      );
}
