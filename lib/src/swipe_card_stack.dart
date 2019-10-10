import 'package:flutter/material.dart';
import 'package:swipe_card/src/swipe_card_item.dart';

final _globalKey = GlobalKey<_SwipeCardStackState>();

final _stackKey = GlobalKey<State<StatefulWidget>>();

enum _FeedbackType { CORRECT, INCORRECT }

class SwipeCardStack<T> extends StatefulWidget {
  final double height;
  final double width;
  final double feedbackWidth;
  final double feedbackHeight;
  final double feedbackMargin;
  final int deckCardsVisible;
  final SwipeCardController swipeController;
  final List<SwipeCardItem> children;
  final Widget acceptButton;
  final Widget rejectButton;
  final Widget correctIndicator;
  final Widget incorrectIndicator;
  final Function(T) onAccepted;
  final Function(T) onRejected;
  final VoidCallback onCompleted;

  SwipeCardStack({
    this.height,
    this.width,
    this.feedbackWidth = 60.0,
    this.feedbackHeight = 48.0,
    this.feedbackMargin = 8.0,
    this.deckCardsVisible = 2,
    this.children = const <SwipeCardItem>[],
    SwipeCardController swipeController,
    this.acceptButton,
    this.rejectButton,
    this.correctIndicator,
    this.incorrectIndicator,
    this.onAccepted,
    this.onRejected,
    this.onCompleted,
  })  : assert(children != null),
        this.swipeController = swipeController ?? SwipeCardController(),
        super(key: _globalKey);

  _SwipeCardStackState<T> createState() => _SwipeCardStackState<T>();
}

class _SwipeCardStackState<T> extends State<SwipeCardStack<T>>
    with TickerProviderStateMixin {
  _SwipeCardAnimationMetrics _metrics;

  final GlobalKey<AnimatedListState> _acceptedListKey =
      GlobalKey<AnimatedListState>();

  final GlobalKey<AnimatedListState> _rejectedListKey =
      GlobalKey<AnimatedListState>();

  final _acceptedCards = <SwipeCardItem<T>>[];

  final _rejectedCards = <SwipeCardItem<T>>[];

  AnimationController controller;

  void initState() {
    super.initState();
    _metrics = _SwipeCardAnimationMetrics(widget.deckCardsVisible);

    _metrics.initCardAnimationParameters();

    _animateDeck(_SwipeCardAnimate.FORWARD);

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        deck(),
        decisionButton(),
        acceptedFeedback(),
        rejectedFeedback(),
      ],
    );
  }

  @override
  void dispose() {
    _metrics.animationsDispose();
    controller.dispose();
    super.dispose();
  }

  Widget deck() {
    return Expanded(
      child: StatefulBuilder(
        key: _stackKey,
        builder: (context, _) {
          _metrics.initDeckAnimationParameters();
          return Stack(
            overflow: Overflow.visible,
            fit: StackFit.passthrough,
            children: widget.children.reversed
                .map(
                  (swiperCard) {
                    return swiperCard == widget.children.last
                        ? _buildCard(swiperCard)
                        : _buildDeck(swiperCard);
                  },
                )
                .toList()
                .reversed
                .toList(),
          );
        },
      ),
    );
  }

  Widget decisionButton() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: (widget.rejectButton is Widget && widget.acceptButton is Widget)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                widget.rejectButton,
                widget.acceptButton,
              ],
            )
          : Container(),
    );
  }

  Widget acceptedFeedback() {
    return feedbackContainer(
      _acceptedCards,
      _acceptedListKey,
      _FeedbackType.CORRECT,
    );
  }

  Widget rejectedFeedback() {
    return SlideTransition(
      position: controller.drive(
        Tween(
          begin: Offset.zero,
          end: Offset(0.0, -1.0),
        ),
      ),
      child: feedbackContainer(
        _rejectedCards,
        _rejectedListKey,
        _FeedbackType.INCORRECT,
      ),
    );
  }

  Widget feedbackContainer(
    List<SwipeCardItem<T>> swipedCards,
    GlobalKey<AnimatedListState> listKey,
    _FeedbackType type,
  ) {
    return SizedBox(
      height: widget.feedbackHeight + 24.0 + 5.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          swipedCardList(listKey, swipedCards, type),
          feedbackIndicator(type, swipedCards),
        ],
      ),
    );
  }

  Widget feedbackIndicator(
    _FeedbackType type,
    List<SwipeCardItem> swipedCards,
  ) {
    return AnimatedBuilder(
      animation: type == _FeedbackType.CORRECT
          ? _metrics._initAcceptedFeedbackIndicatorAnimation()
          : _metrics._initRejectedFeedbackIndicatorAnimation(),
      builder: (_, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36.0),
            color: type == _FeedbackType.CORRECT ? Colors.green : Colors.red,
          ),
          margin: const EdgeInsets.only(
            top: 8.0,
            left: 16.0,
            bottom: 16.0,
            right: 16.0,
          ),
          height: 5.0,
          width: swipedCards.length *
                  (widget.feedbackWidth + widget.feedbackMargin * 2) +
              (swipedCards.isNotEmpty ? 8.0 : 0.0),
        );
      },
    );
  }

  Widget swipedCardList(
    GlobalKey<AnimatedListState> listKey,
    List<SwipeCardItem> swipedCards,
    _FeedbackType type,
  ) {
    return Flexible(
      child: AnimatedList(
        key: listKey,
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index, animation) {
          return swipedCardItem(
            animation,
            swipedCards,
            InkWell(
              child: swipedCards[index],
              onTap: () {
                final item = swipedCards.removeAt(index);

                final reverseAnimationDuration =
                    const Duration(milliseconds: 500);

                listKey.currentState.removeItem(
                  index,
                  (context, reverseAnimation) {
                    return swipedCardItem(
                      reverseAnimation,
                      swipedCards,
                      item,
                    );
                  },
                  duration: reverseAnimationDuration,
                );

                Future.delayed(reverseAnimationDuration, () {
                  _addOnDeckAndUpdate(item, type);
                  _metrics.animateFeedbackIndicator(
                      type, _SwipeCardAnimate.REVERSE);
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget swipedCardItem(
    Animation<double> animation,
    List<SwipeCardItem> swipedCards,
    Widget content,
  ) {
    return ScaleTransition(
      scale: animation.drive(
        CurveTween(
          curve: Curves.elasticOut,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          height: widget.feedbackHeight,
          width: widget.feedbackWidth,
          child: content,
        ),
      ),
    );
  }

  void _animateDeck(_SwipeCardAnimate animate, {double from}) {
    _metrics.animateDeck(
      animate,
      from: from,
    );
  }

  void _onAcceptedCard(SwipeCardItem swipedCard) {
    if (widget.onAccepted != null) widget.onAccepted(swipedCard.value);
    if (_acceptedCards.isEmpty) controller.reverse();
    _acceptedCards.add(swipedCard);
    _acceptedListKey.currentState.insertItem(
      _acceptedCards.indexOf(swipedCard),
      duration: const Duration(milliseconds: 250),
    );
    _metrics.animateFeedbackIndicator(
      _FeedbackType.CORRECT,
      _SwipeCardAnimate.FORWARD,
    );
    _removeFromDeckAndUpdate(swipedCard);
  }

  void _onRejectedCard(SwipeCardItem swipedCard) {
    if (widget.onRejected != null) widget.onRejected(swipedCard.value);
    if (_acceptedCards.isEmpty) controller.forward();
    _rejectedCards.add(swipedCard);
    _rejectedListKey.currentState.insertItem(
      _rejectedCards.length - 1,
      duration: const Duration(milliseconds: 250),
    );
    _metrics.animateFeedbackIndicator(
      _FeedbackType.INCORRECT,
      _SwipeCardAnimate.FORWARD,
    );
    _removeFromDeckAndUpdate(swipedCard);
  }

  void _onCompleted() {
    if (widget.onCompleted != null) widget.onCompleted();
  }

  void _removeFromDeckAndUpdate(SwipeCardItem swiperCard) {
    _stackKey.currentState.setState(() {
      widget.children.remove(swiperCard);
      if (widget.children.isEmpty) _onCompleted();
      widget.swipeController.currentCard = null;
      _animateDeck(_SwipeCardAnimate.FORWARD, from: 1.0);
      _metrics.initCardAnimationParameters();
    });
  }

  void _addOnDeckAndUpdate(SwipeCardItem swiperCard, _FeedbackType type) {
    if (_acceptedCards.isEmpty) controller.forward();
    _stackKey.currentState.setState(() {
      widget.children.add(swiperCard);
      widget.swipeController.currentCard = null;
      _animateDeck(_SwipeCardAnimate.FORWARD, from: 0.0);
      _metrics.initReverseCardAnimationParameters(type);
    });
  }

  Widget _buildDeck(SwipeCardItem swiperCard) {
    return Center(
      child: SlideTransition(
        position: _metrics.deckAnimatedPosition(),
        child: ScaleTransition(
          scale: _metrics.deckAnimatedScale(),
          child: _createContentCard(
            swiperCard,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(SwipeCardItem child) {
    widget.swipeController.currentCard = child;
    return Center(
      child: Transform.translate(
        offset: _metrics.currentCardPosition,
        child: Transform.rotate(
          angle: _metrics.cardAngle,
          child: _createGestureCard(child),
        ),
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
          _metrics.animateDeck(_SwipeCardAnimate.REVERSE);
        },
        onPanUpdate: (DragUpdateDetails details) {
          _metrics.resetCardAnimation();
          _metrics.updateCardPositionAndRotation(delta: details.delta);
        },
        onPanEnd: (DragEndDetails details) {
          if (_metrics.currentCardPosition == Offset.zero) {
            return _metrics.animateCardOnSwipeStartFeedback();
          }
          final cardRenderBox = context.findRenderObject() as RenderBox;
          final cardSize = cardRenderBox.size;
          final listener = _metrics.updateCardPositionAndRotation;
          if (_metrics.isCardInsideEdges(cardSize.width)) {
            _metrics.animateCardReturn(listener);
            _animateDeck(_SwipeCardAnimate.FORWARD);
          } else {
            if (_metrics.currentCardPosition.dx > 0)
              widget.swipeController
                  .acceptCard(targetOffset: details.velocity.pixelsPerSecond);
            else
              widget.swipeController
                  .rejectCard(targetOffset: details.velocity.pixelsPerSecond);
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

  void animateCardSwipe(Offset targetOffset, Function statusListener) {
    _metrics.animateCardSwipe(
      targetOffset,
      statusListener,
    );
  }
}

class SwipeCardController {
  SwipeCardItem _currentCard;

  set currentCard(SwipeCardItem currentCard) => _currentCard = currentCard;

  void acceptCard({Offset targetOffset}) {
    if (_currentCard == null) return _globalKey.currentState._onCompleted();
    if (targetOffset == null)
      targetOffset = Offset(
        (_globalKey.currentContext.findRenderObject() as RenderBox).size.width +
            500,
        -100,
      );
    _globalKey.currentState._animateDeck(_SwipeCardAnimate.REVERSE);
    _globalKey.currentState.animateCardSwipe(targetOffset, (status) {
      if (status == AnimationStatus.completed)
        _globalKey.currentState._onAcceptedCard(_currentCard);
    });
  }

  void rejectCard({Offset targetOffset}) {
    if (_currentCard == null) return _globalKey.currentState._onCompleted();
    if (targetOffset == null)
      targetOffset = Offset(
          -(_globalKey.currentContext.findRenderObject() as RenderBox)
                  .size
                  .width -
              500,
          -100);
    _globalKey.currentState._animateDeck(_SwipeCardAnimate.REVERSE);
    _globalKey.currentState.animateCardSwipe(targetOffset, (status) {
      if (status == AnimationStatus.completed)
        _globalKey.currentState._onRejectedCard(_currentCard);
    });
  }
}

enum _SwipeCardAnimate { FORWARD, REVERSE }

class _SwipeCardAnimationMetrics {
  final int _cardsToTranslate;
  AnimationController _cardAnimationController;
  AnimationController _deckAnimationController;
  AnimationController _acceptedIndicatorController;
  AnimationController _rejectedIndicatorController;
  Animation<Offset> _cardAnimation;
  Offset currentCardPosition;
  Offset _deckPosition;
  double _cardAngle;
  double _deckScale;

  _SwipeCardAnimationMetrics(this._cardsToTranslate);

  double get cardAngle => _cardAngle;

  void initCardAnimationParameters() {
    currentCardPosition = Offset.zero;
    _cardAngle = 0.0;
  }

  void initReverseCardAnimationParameters(_FeedbackType type) {
    currentCardPosition =
        Offset(type == _FeedbackType.CORRECT ? 500.0 : -500.0, 0);
    _cardAngle = 0.0;
    animateCardReturn(updateCardPositionAndRotation);
  }

  void _initCardAnimation(int milliseconds, Offset endOffset, Curve curve) {
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: milliseconds),
      vsync: _globalKey.currentState,
    );
    _cardAnimation = Tween<Offset>(
      begin: currentCardPosition,
      end: endOffset,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: curve,
      ),
    );
  }

  void initDeckAnimationParameters() {
    _deckPosition = Offset.zero;
    _deckScale = 1.0;
  }

  void _initDeckAnimation() {
    initDeckAnimationParameters();
    _deckAnimationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: _globalKey.currentState,
    );
  }

  Animation<double> _initAcceptedFeedbackIndicatorAnimation() {
    return _acceptedIndicatorController = AnimationController(
      vsync: _globalKey.currentState,
      duration: const Duration(milliseconds: 250),
    );
  }

  Animation<double> _initRejectedFeedbackIndicatorAnimation() {
    return _rejectedIndicatorController = AnimationController(
      vsync: _globalKey.currentState,
      duration: const Duration(milliseconds: 250),
    );
  }

  Animation<Offset> deckAnimatedPosition() {
    final translateUnit = .08;
    return Tween<Offset>(
      begin: _deckPosition,
      end: _deckPosition.dy < _cardsToTranslate * translateUnit
          ? _deckPosition = _deckPosition.translate(.0, translateUnit)
          : _deckPosition,
    ).animate(CurvedAnimation(
        parent: _deckAnimationController, curve: Curves.easeInBack));
  }

  Animation<double> deckAnimatedScale() {
    return Tween<double>(
      begin: _deckScale,
      end: _deckScale > _cardsToTranslate * (-.1)
          ? _deckScale -= .1
          : _deckScale,
    ).animate(CurvedAnimation(
        parent: _deckAnimationController, curve: Curves.easeInBack));
  }

  void animateCardOnSwipeStartFeedback() {
    if (isAnimationControllerBusy(_cardAnimationController)) return;
    initCardAnimationParameters();
    final dxFeedback =
        (_globalKey.currentContext.findRenderObject() as RenderBox).size.width /
            25;
    _initCardAnimation(150, Offset(-dxFeedback, 0.0), Curves.linear);
    _cardAnimation.addListener(updateCardPositionAndRotation);
    _cardAnimationController.forward();
    _cardAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        initCardAnimationParameters();
        _initCardAnimation(150, Offset(dxFeedback, 0.0), Curves.linear);
        _cardAnimation.addListener(updateCardPositionAndRotation);
        _cardAnimation.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _cardAnimationController.reverse();
            animateDeck(_SwipeCardAnimate.FORWARD);
          }
        });
        _cardAnimationController.forward();
      }
    });
  }

  void animateCardSwipe(Offset targetOffset, Function statusListener) {
    if (isAnimationControllerBusy(_cardAnimationController)) return;
    final targetPosition = currentCardPosition.translate(
        2 * currentCardPosition.dx + targetOffset.dx,
        2 * currentCardPosition.dy + targetOffset.dy);
    _initCardAnimation(500, targetPosition, Curves.linear);
    _cardAnimation.addStatusListener(statusListener);
    _cardAnimation.addListener(updateCardPositionAndRotation);
    _cardAnimationController.forward();
  }

  void animateCardReturn(VoidCallback listener) {
    if (isAnimationControllerBusy(_cardAnimationController)) return;
    _initCardAnimation(1000, Offset.zero, Curves.elasticOut);
    _initDeckAnimation();
    _cardAnimation.addListener(listener);
    _cardAnimationController.forward();
  }

  void animateDeck(_SwipeCardAnimate animate, {double from}) {
    if (_deckAnimationController == null) _initDeckAnimation();
    if (animate == _SwipeCardAnimate.FORWARD)
      _deckAnimationController.forward(from: from);
    else
      _deckAnimationController.reverse(from: from);
  }

  void animateFeedbackIndicator(
    _FeedbackType type,
    _SwipeCardAnimate animate,
  ) async {
    final feedbackController = type == _FeedbackType.CORRECT
        ? _acceptedIndicatorController
        : _rejectedIndicatorController;
    if (animate == _SwipeCardAnimate.FORWARD)
      await feedbackController.forward();
    else
      await feedbackController.reverse();
    feedbackController.reset();
  }

  void resetCardAnimation() {
    if (isAnimationControllerBusy(_cardAnimationController)) {
      _cardAnimationController.reset();
      initCardAnimationParameters();
    }
  }

  void updateCardPositionAndRotation({Offset delta}) {
    _stackKey.currentState.setState(() {
      delta != null
          ? _calcPosition(currentCardPosition, delta)
          : currentCardPosition = _cardAnimation.value;
      _calcAngle(currentCardPosition);
    });
  }

  bool isAnimationControllerBusy(AnimationController controller) =>
      (controller?.status == AnimationStatus.forward ||
          controller?.status == AnimationStatus.reverse);

  bool isCardInsideEdges(double cardWidth) {
    return currentCardPosition.dx < 0.4 * cardWidth &&
        currentCardPosition.dx > -0.4 * cardWidth;
  }

  double _calcAngle(Offset pos) => _cardAngle = pos.dx * 0.003;

  Offset _calcPosition(Offset currentPosition, Offset delta) =>
      currentCardPosition =
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
    if (_acceptedIndicatorController?.status == AnimationStatus.forward ||
        _acceptedIndicatorController?.status == AnimationStatus.reverse)
      _acceptedIndicatorController.reset();
    _acceptedIndicatorController?.dispose();
  }
}
