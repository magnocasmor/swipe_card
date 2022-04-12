import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:swipe_card/src/swipe_card_item.dart';

enum _FeedbackType { CORRECT, INCORRECT }

class SwipeCardStack<T> extends StatefulWidget {
  final double? height;
  final double? width;
  final double feedbackWidth;
  final double feedbackHeight;
  final double feedbackMargin;
  final int deckCardsVisible;
  final EdgeInsets deckPadding;
  final SwipeCardController swipeController;
  final List<SwipeCardItem> children;
  final Widget? completedWidget;
  final Widget? acceptButton;
  final Widget? rejectButton;
  final Widget? correctIndicator;
  final Widget? incorrectIndicator;
  final Function(T)? onAccepted;
  final Function(T)? onRejected;
  final Function(T)? onReview;
  final VoidCallback? onCompleted;

  SwipeCardStack({
    required this.children,
    required this.swipeController,
    this.height,
    this.width,
    this.feedbackWidth = 90.0,
    this.feedbackHeight = 78.0,
    this.feedbackMargin = 8.0,
    this.deckCardsVisible = 2,
    this.deckPadding = const EdgeInsets.all(0.0),
    this.completedWidget,
    this.acceptButton,
    this.rejectButton,
    this.correctIndicator,
    this.incorrectIndicator,
    this.onAccepted,
    this.onRejected,
    this.onReview,
    this.onCompleted,
  })  : assert(children is List<SwipeCardItem<T>>),
        super(key: swipeController._swipeCardKey);

  _SwipeCardStackState<T> createState() => _SwipeCardStackState<T>();
}

class _SwipeCardStackState<T> extends State<SwipeCardStack<T?>> with TickerProviderStateMixin {
  late _SwipeCardAnimationMetrics _metrics;

  final stackKey = GlobalKey<State<StatefulWidget>>();

  final GlobalKey<AnimatedListState> _acceptedListKey = GlobalKey<AnimatedListState>();

  final GlobalKey<AnimatedListState> _rejectedListKey = GlobalKey<AnimatedListState>();

  final List<SwipeCardItem<T?>> itens = <SwipeCardItem<T>>[];

  final List<SwipeCardItem<T?>?> _acceptedCards = <SwipeCardItem<T>?>[];

  final List<SwipeCardItem<T?>?> _rejectedCards = <SwipeCardItem<T>?>[];

  void initState() {
    super.initState();

    itens.addAll(List.from(widget.children));

    _metrics = _SwipeCardAnimationMetrics(
        widget.key as GlobalKey<_SwipeCardStackState<dynamic>>?, widget.deckCardsVisible);

    _metrics.initCardAnimationParameters();

    _metrics.initRejectedAnimation();

    _animateDeck(_SwipeCardAnimate.FORWARD);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        _deck(),
        _decisionButton(),
        _acceptedFeedback(),
        _rejectedFeedback(),
      ],
    );
  }

  @override
  void dispose() {
    _metrics.animationsDispose();
    super.dispose();
  }

  Widget _deck() {
    return StatefulBuilder(
      key: stackKey,
      builder: (_, __) {
        _metrics.initDeckAnimationParameters();
        return Padding(
          padding: widget.deckPadding,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.passthrough,
            children: [
              if (widget.completedWidget is Widget)
                Align(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: itens.isEmpty ? 1.0 : 0.0,
                    child: widget.completedWidget,
                  ),
                ),
              ...itens.reversed
                  .map(
                    (swiperCard) {
                      return swiperCard == itens.last
                          ? _buildCard(swiperCard)
                          : _buildDeck(swiperCard);
                    },
                  )
                  .toList()
                  .reversed
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _decisionButton() {
    final cardHeight =
        MediaQuery.of(context).size.width - widget.deckPadding.along(Axis.horizontal);
    final padding = ((cardHeight * .08) * .38) * widget.deckCardsVisible;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          if (widget.rejectButton is Widget && widget.acceptButton is Widget) ...[
            widget.rejectButton!,
            widget.acceptButton!,
          ]
        ],
      ),
    );
  }

  Widget _acceptedFeedback() {
    return _feedbackContainer(
      _acceptedCards,
      _acceptedListKey,
      _FeedbackType.CORRECT,
    );
  }

  Widget _rejectedFeedback() {
    return SlideTransition(
      position: _metrics._rejectedSlideController!.drive(
        Tween(
          begin: Offset.zero,
          end: Offset(0.0, -1.0),
        ),
      ),
      child: _feedbackContainer(
        _rejectedCards,
        _rejectedListKey,
        _FeedbackType.INCORRECT,
      ),
    );
  }

  Widget _feedbackContainer(
    List<SwipeCardItem<T?>?> swipedCards,
    GlobalKey<AnimatedListState> listKey,
    _FeedbackType type,
  ) {
    return SizedBox(
      height: widget.feedbackHeight + 24.0 + 5.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _swipedCardList(listKey, swipedCards, type),
          _feedbackIndicator(type, swipedCards),
        ],
      ),
    );
  }

  Widget _feedbackIndicator(
    _FeedbackType type,
    List<SwipeCardItem?> swipedCards,
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
          width: swipedCards.length * (widget.feedbackWidth + widget.feedbackMargin * 2) +
              (swipedCards.isNotEmpty ? 8.0 : 0.0),
        );
      },
    );
  }

  Widget _swipedCardList(
    GlobalKey<AnimatedListState> listKey,
    List<SwipeCardItem?> swipedCards,
    _FeedbackType type,
  ) {
    return Flexible(
      child: AnimatedList(
        key: listKey,
        shrinkWrap: true,
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index, animation) {
          return _swipedCardItem(
            animation,
            swipedCards,
            InkWell(
              child: swipedCards[index],
              onTap: () {
                final item = swipedCards.removeAt(index)!;

                final reverseAnimationDuration = const Duration(milliseconds: 250);

                widget.onReview?.call(item.value);

                listKey.currentState!.removeItem(
                  index,
                  (context, reverseAnimation) {
                    reverseAnimation.addListener(() async {
                      if (reverseAnimation.isDismissed) {
                        _metrics.animateFeedbackIndicator(type, _SwipeCardAnimate.REVERSE);

                        await Future.delayed(reverseAnimationDuration);

                        _addOnDeckAndUpdate(item, type);

                        animateRejectedFeedback();
                      }
                    });
                    return _swipedCardItem(
                      reverseAnimation,
                      swipedCards,
                      item,
                    );
                  },
                  duration: reverseAnimationDuration,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> animateRejectedFeedback() async {
    if (_acceptedCards.isEmpty) {
      await _metrics.animateRejectedSlide(_SwipeCardAnimate.FORWARD);
    } else if (_rejectedCards.isNotEmpty) {
      await _metrics.animateRejectedSlide(_SwipeCardAnimate.REVERSE);
    } else {
      _metrics.resetRejectedSlideAnimation();
    }
  }

  Widget _swipedCardItem(
    Animation<double> animation,
    List<SwipeCardItem?> swipedCards,
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

  void _animateDeck(_SwipeCardAnimate animate, {double? from}) {
    _metrics.animateDeck(
      animate,
      from: from,
    );
  }

  Future<void> onAcceptedCard(SwipeCardItem? swipedCard) async {
    if (widget.onAccepted != null) widget.onAccepted!(swipedCard!.value);

    _acceptedCards.add(swipedCard as SwipeCardItem<T?>?);

    await animateRejectedFeedback();

    _acceptedListKey.currentState!.insertItem(
      _acceptedCards.indexOf(swipedCard),
      duration: const Duration(milliseconds: 250),
    );

    _metrics.animateFeedbackIndicator(
      _FeedbackType.CORRECT,
      _SwipeCardAnimate.FORWARD,
    );

    _removeFromDeckAndUpdate(swipedCard);

    itens.remove(swipedCard);
  }

  Future<void> onRejectedCard(SwipeCardItem? swipedCard) async {
    if (widget.onRejected != null) widget.onRejected!(swipedCard!.value);

    _rejectedCards.add(swipedCard as SwipeCardItem<T?>?);

    await animateRejectedFeedback();

    _rejectedListKey.currentState!.insertItem(
      _rejectedCards.indexOf(swipedCard),
      duration: const Duration(milliseconds: 250),
    );

    _metrics.animateFeedbackIndicator(
      _FeedbackType.INCORRECT,
      _SwipeCardAnimate.FORWARD,
    );

    _removeFromDeckAndUpdate(swipedCard);

    itens.remove(swipedCard);
  }

  void onCompleted() {
    if (widget.onCompleted != null) widget.onCompleted!();
  }

  void _removeFromDeckAndUpdate(SwipeCardItem? swiperCard) {
    stackKey.currentState!.setState(() {
      itens.remove(swiperCard);

      if (itens.isEmpty) onCompleted();

      widget.swipeController.currentCard = null;

      _animateDeck(_SwipeCardAnimate.FORWARD, from: 1.0);

      _metrics.initCardAnimationParameters();
    });
  }

  void _addOnDeckAndUpdate(SwipeCardItem swiperCard, _FeedbackType type) {
    stackKey.currentState!.setState(() {
      widget.swipeController.currentCard = null;

      _animateDeck(_SwipeCardAnimate.FORWARD, from: 0.0);

      _metrics.initReverseCardAnimationParameters(type);

      itens.add(swiperCard as SwipeCardItem<T?>);
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
        offset: _metrics.currentCardPosition!,
        child: Transform.rotate(
          angle: _metrics.cardAngle!,
          child: _createGestureCard(child),
        ),
      ),
    );
  }

  double _calcOpacity() {
    double opacity = (_metrics.currentCardPosition!.dx * .01).abs();
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

  Widget _createGestureCard(SwipeCardItem swiperCard) {
    return GestureDetector(
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
        final void Function({Offset delta}) listener = _metrics.updateCardPositionAndRotation;
        if (_metrics.isCardInsideEdges(cardSize.width)) {
          _metrics.animateCardReturn(listener);
          _animateDeck(_SwipeCardAnimate.FORWARD);
        } else {
          if (_metrics.currentCardPosition!.dx > 0)
            widget.swipeController.acceptCard(targetOffset: details.velocity.pixelsPerSecond);
          else
            widget.swipeController.rejectCard(targetOffset: details.velocity.pixelsPerSecond);
        }
      },
      child: Stack(
        children: <Widget>[
          _createContentCard(swiperCard),
          Positioned(
            top: widget.height != null ? widget.height! * .03 : 30.0,
            left: widget.width != null ? widget.width! * .03 : 30.0,
            child: Opacity(
              opacity: (_metrics.currentCardPosition!.dx >
                      (widget.width != null ? widget.width! * 0.3 : 50))
                  ? _calcOpacity()
                  : 0.0,
              child: widget.correctIndicator,
            ),
          ),
          Positioned(
            top: widget.height != null ? widget.height! * .03 : 30.0,
            right: widget.width != null ? widget.width! * .03 : 30.0,
            child: Opacity(
              opacity: (_metrics.currentCardPosition!.dx <
                      (widget.width != null ? -widget.width! * 0.3 : -50))
                  ? _calcOpacity()
                  : 0.0,
              child: widget.incorrectIndicator,
            ),
          ),
        ],
      ),
    );
  }

  void animateCardSwipe(Offset targetOffset, Function statusListener) {
    _metrics.animateCardSwipe(
      targetOffset,
      statusListener,
    );
  }
}

class SwipeCardController<T> {
  final _swipeCardKey = GlobalKey<_SwipeCardStackState>();

  SwipeCardItem<T?>? _currentCard;

  set currentCard(SwipeCardItem? currentCard) => _currentCard = currentCard as SwipeCardItem<T?>?;

  void acceptCard({Offset? targetOffset}) {
    if (_currentCard == null) return _swipeCardKey.currentState!.onCompleted();
    if (targetOffset == null)
      targetOffset = Offset(
        (_swipeCardKey.currentContext!.findRenderObject() as RenderBox).size.width + 500,
        -100,
      );
    _swipeCardKey.currentState!._animateDeck(_SwipeCardAnimate.REVERSE);
    _swipeCardKey.currentState!.animateCardSwipe(targetOffset, (status) {
      if (status == AnimationStatus.completed)
        _swipeCardKey.currentState!.onAcceptedCard(_currentCard);
    });
  }

  void rejectCard({Offset? targetOffset}) {
    if (_currentCard == null) return _swipeCardKey.currentState!.onCompleted();
    if (targetOffset == null)
      targetOffset = Offset(
          -(_swipeCardKey.currentContext!.findRenderObject() as RenderBox).size.width - 500, -100);
    _swipeCardKey.currentState!._animateDeck(_SwipeCardAnimate.REVERSE);
    _swipeCardKey.currentState!.animateCardSwipe(targetOffset, (status) {
      if (status == AnimationStatus.completed)
        _swipeCardKey.currentState!.onRejectedCard(_currentCard);
    });
  }

  Future<void> completeSwipe({
    List<T> accepteds = const [],
    List<T> rejecteds = const [],
  }) async {
    final swipeDeck = _swipeCardKey.currentState;

    final children = _swipeCardKey.currentState!.itens;

    if (children.isEmpty) return;

    for (int i = 0; i < accepteds.length; i++) {
      final item = children.singleWhereOrNull((item) {
        return item.value == accepteds[i];
      });
      if (item == null) continue;
      await swipeDeck!.onAcceptedCard(item);
    }

    for (int i = 0; i < rejecteds.length; i++) {
      final item = children.singleWhereOrNull((item) {
        return item.value == rejecteds[i];
      });
      if (item == null) continue;
      await swipeDeck!.onRejectedCard(item);
    }
  }
}

enum _SwipeCardAnimate { FORWARD, REVERSE }

class _SwipeCardAnimationMetrics {
  final GlobalKey<_SwipeCardStackState>? _swipeCardKey;
  final int _cardsToTranslate;
  AnimationController? _cardAnimationController;
  AnimationController? _deckAnimationController;
  AnimationController? _acceptedIndicatorController;
  late AnimationController _rejectedIndicatorController;
  AnimationController? _rejectedSlideController;
  late Animation<Offset> _cardAnimation;
  Offset? currentCardPosition;
  Offset? _deckPosition;
  double? _cardAngle;
  late double _deckScale;

  _SwipeCardAnimationMetrics(this._swipeCardKey, this._cardsToTranslate);

  double? get cardAngle => _cardAngle;

  void initCardAnimationParameters() {
    currentCardPosition = Offset.zero;
    _cardAngle = 0.0;
  }

  void initRejectedAnimation() {
    _rejectedSlideController = AnimationController(
      vsync: _swipeCardKey!.currentState!,
      duration: const Duration(milliseconds: 250),
    );
  }

  void initReverseCardAnimationParameters(_FeedbackType type) {
    currentCardPosition = Offset(type == _FeedbackType.CORRECT ? 500.0 : -500.0, 0);
    _cardAngle = 0.0;
    animateCardReturn(updateCardPositionAndRotation);
  }

  void _initCardAnimation(int milliseconds, Offset endOffset, Curve curve) {
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: milliseconds),
      vsync: _swipeCardKey!.currentState!,
    );
    _cardAnimation = Tween<Offset>(
      begin: currentCardPosition,
      end: endOffset,
    ).animate(
      CurvedAnimation(
        parent: _cardAnimationController!,
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
      vsync: _swipeCardKey!.currentState!,
    );
  }

  Animation<double> _initAcceptedFeedbackIndicatorAnimation() {
    return _acceptedIndicatorController = AnimationController(
      vsync: _swipeCardKey!.currentState!,
      duration: const Duration(milliseconds: 250),
    );
  }

  Animation<double> _initRejectedFeedbackIndicatorAnimation() {
    return _rejectedIndicatorController = AnimationController(
      vsync: _swipeCardKey!.currentState!,
      duration: const Duration(milliseconds: 250),
    );
  }

  Animation<Offset> deckAnimatedPosition() {
    final translateUnit = .08;
    return Tween<Offset>(
      begin: _deckPosition,
      end: _deckPosition!.dy < _cardsToTranslate * translateUnit
          ? _deckPosition = _deckPosition!.translate(.0, translateUnit)
          : _deckPosition,
    ).animate(CurvedAnimation(parent: _deckAnimationController!, curve: Curves.easeInBack));
  }

  Animation<double> deckAnimatedScale() {
    return Tween<double>(
      begin: _deckScale,
      end: _deckScale > _cardsToTranslate * (-.1) ? _deckScale -= .1 : _deckScale,
    ).animate(CurvedAnimation(parent: _deckAnimationController!, curve: Curves.easeInBack));
  }

  void animateCardOnSwipeStartFeedback() {
    if (isAnimationControllerBusy(_cardAnimationController)) return;
    initCardAnimationParameters();
    final dxFeedback =
        (_swipeCardKey!.currentContext!.findRenderObject() as RenderBox).size.width / 25;
    _initCardAnimation(150, Offset(-dxFeedback, 0.0), Curves.linear);
    _cardAnimation.addListener(updateCardPositionAndRotation);
    _cardAnimationController!.forward();
    _cardAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        initCardAnimationParameters();
        _initCardAnimation(150, Offset(dxFeedback, 0.0), Curves.linear);
        _cardAnimation.addListener(updateCardPositionAndRotation);
        _cardAnimation.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _cardAnimationController!.reverse();
            animateDeck(_SwipeCardAnimate.FORWARD);
          }
        });
        _cardAnimationController!.forward();
      }
    });
  }

  void animateCardSwipe(Offset targetOffset, Function statusListener) {
    if (isAnimationControllerBusy(_cardAnimationController)) return;
    final targetPosition = currentCardPosition!.translate(
        2 * currentCardPosition!.dx + targetOffset.dx,
        2 * currentCardPosition!.dy + targetOffset.dy);
    _initCardAnimation(500, targetPosition, Curves.linear);
    _cardAnimation.addStatusListener(statusListener as void Function(AnimationStatus));
    _cardAnimation.addListener(updateCardPositionAndRotation);
    _cardAnimationController!.forward();
  }

  void animateCardReturn(VoidCallback listener) {
    if (isAnimationControllerBusy(_cardAnimationController)) return;
    _initCardAnimation(1000, Offset.zero, Curves.elasticOut);
    _cardAnimation.addListener(listener);
    _cardAnimationController!.forward();
  }

  void animateDeck(_SwipeCardAnimate animate, {double? from}) {
    if (_deckAnimationController == null) _initDeckAnimation();
    if (animate == _SwipeCardAnimate.FORWARD)
      _deckAnimationController!.forward(from: from);
    else
      _deckAnimationController!.reverse(from: from);
  }

  void animateFeedbackIndicator(
    _FeedbackType type,
    _SwipeCardAnimate animate,
  ) async {
    final feedbackController = type == _FeedbackType.CORRECT
        ? _acceptedIndicatorController!
        : _rejectedIndicatorController;
    if (animate == _SwipeCardAnimate.FORWARD)
      await feedbackController.forward();
    else
      await feedbackController.reverse();
    feedbackController.reset();
  }

  Future<void> animateRejectedSlide(_SwipeCardAnimate animate) async {
    if (animate == _SwipeCardAnimate.FORWARD)
      await _rejectedSlideController!.forward();
    else
      await _rejectedSlideController!.reverse();
  }

  void resetCardAnimation() {
    if (isAnimationControllerBusy(_cardAnimationController)) {
      _cardAnimationController!.reset();
      initCardAnimationParameters();
    }
  }

  void resetRejectedSlideAnimation() {
    _rejectedSlideController!.reset();
  }

  void updateCardPositionAndRotation({Offset? delta}) {
    _swipeCardKey!.currentState!.stackKey.currentState!.setState(() {
      delta != null
          ? _calcPosition(currentCardPosition!, delta)
          : currentCardPosition = _cardAnimation.value;
      _calcAngle(currentCardPosition!);
    });
  }

  bool isAnimationControllerBusy(AnimationController? controller) =>
      (controller?.status == AnimationStatus.forward ||
          controller?.status == AnimationStatus.reverse);

  bool isCardInsideEdges(double cardWidth) {
    return currentCardPosition!.dx < 0.4 * cardWidth && currentCardPosition!.dx > -0.4 * cardWidth;
  }

  double _calcAngle(Offset pos) => _cardAngle = pos.dx * 0.003;

  Offset _calcPosition(Offset currentPosition, Offset delta) =>
      currentCardPosition = Offset(currentPosition.dx + delta.dx, currentPosition.dy + delta.dy);

  void animationsDispose() {
    if (_cardAnimationController?.status == AnimationStatus.forward ||
        _cardAnimationController?.status == AnimationStatus.reverse)
      _cardAnimationController!.reset();
    _cardAnimationController?.dispose();

    if (_deckAnimationController?.status == AnimationStatus.forward ||
        _deckAnimationController?.status == AnimationStatus.reverse)
      _deckAnimationController!.reset();
    _deckAnimationController?.dispose();

    if (_acceptedIndicatorController?.status == AnimationStatus.forward ||
        _acceptedIndicatorController?.status == AnimationStatus.reverse)
      _acceptedIndicatorController!.reset();
    _acceptedIndicatorController?.dispose();

    if (_rejectedSlideController?.status == AnimationStatus.forward ||
        _rejectedSlideController?.status == AnimationStatus.reverse)
      _rejectedSlideController!.reset();
    _rejectedSlideController?.dispose();
  }
}
