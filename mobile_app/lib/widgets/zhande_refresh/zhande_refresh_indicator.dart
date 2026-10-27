import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'zhande_refresh_constants.dart';
import 'zhande_refresh_state.dart';
import 'zhande_refresh_header.dart';

/// Custom pull-to-refresh indicator with the brand 站队 animation.
///
/// Manages the full refresh state machine internally:
///   idle → pulling → ready → refreshing → success → closing → idle
///
/// Usage:
/// ```dart
/// ZhandeRefreshIndicator(
///   onRefresh: () async { await loadData(); },
///   child: ListView(...),
/// )
/// ```
class ZhandeRefreshIndicator extends StatefulWidget {
  const ZhandeRefreshIndicator({
    required this.child,
    required this.onRefresh,
    this.triggerDistance = kZhandeTriggerDistance,
    this.successDuration = kZhandeSuccessDuration,
    this.enableSuccessText = true,
    super.key,
  });

  /// The scrollable widget to be pulled down.
  final Widget child;

  /// Called when the refresh is triggered.
  final Future<void> Function() onRefresh;

  /// Distance in pixels that the user must pull to trigger refresh.
  final double triggerDistance;

  /// Duration the success message is shown before closing.
  final Duration successDuration;

  /// Whether to show the random success text after refresh.
  final bool enableSuccessText;

  @override
  State<ZhandeRefreshIndicator> createState() => _ZhandeRefreshIndicatorState();
}

class _ZhandeRefreshIndicatorState extends State<ZhandeRefreshIndicator>
    with TickerProviderStateMixin {
  // ── Animation controllers ──
  late final AnimationController _bounceController;
  late final AnimationController _breathingController;
  late final AnimationController _glowController;
  late final AnimationController _closeController;

  // ── Animation values ──
  late final Animation<double> _bounceScale;
  late final Animation<double> _breathingScale;
  late final Animation<double> _breathingOpacity;

  // ── State ──
  final _random = Random();
  double _pullDistance = 0;
  int _completeMessageIndex = 0;
  ZhandeRefreshState _refreshState = ZhandeRefreshState.idle;

  // ── Getters ──
  bool get _isRefreshing => _refreshState == ZhandeRefreshState.refreshing;
  bool get _isSuccess => _refreshState == ZhandeRefreshState.success;
  bool get _isClosing => _refreshState == ZhandeRefreshState.closing;

  double get _triggerDistance => widget.triggerDistance;

  double get _headerHeight {
    if (_isClosing) return _closeController.value * _triggerDistance;
    if (_isRefreshing || _isSuccess) return _triggerDistance;
    return _pullDistance;
  }

  // ── Lifecycle ──

  @override
  void initState() {
    super.initState();

    _bounceController = AnimationController(
      vsync: this,
      duration: kZhandeBounceDuration,
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 0.96), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 45),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: kZhandeBreathingDuration,
    );
    _breathingScale = Tween<double>(begin: 0.90, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: kZhandeGlowDuration,
    );

    _closeController = AnimationController(
      vsync: this,
      duration: kZhandeCloseDuration,
    );
    _closeController.addListener(_onCloseUpdate);
  }

  @override
  void dispose() {
    _closeController.removeListener(_onCloseUpdate);
    _bounceController.dispose();
    _breathingController.dispose();
    _glowController.dispose();
    _closeController.dispose();
    super.dispose();
  }

  // ── Close animation listener ──

  void _onCloseUpdate() {
    if (!mounted) return;
    if (_closeController.isDismissed && _isClosing) {
      debugPrint('_ZhandeRefresh: Closing -> Idle');
      setState(() {
        _pullDistance = 0;
        _refreshState = ZhandeRefreshState.idle;
      });
    } else if (_isClosing) {
      setState(() {});
    }
  }

  // ── Scroll handling ──

  bool _handleScroll(ScrollNotification notification) {
    if (_isRefreshing || _isSuccess || _isClosing) return false;

    final atTop = notification.metrics.pixels <=
        notification.metrics.minScrollExtent + 0.5;

    if (notification is ScrollStartNotification && atTop) {
      if (_isClosing) return false;
      setState(() {
        _pullDistance = 0;
        _refreshState = ZhandeRefreshState.idle;
      });
      debugPrint('_ZhandeRefresh: ScrollStart -> Idle');
    } else if (notification is OverscrollNotification && atTop) {
      if (_isClosing) return false;
      final overscroll = notification.overscroll;
      if (overscroll != 0) {
        final nextPull =
            (_pullDistance - overscroll).clamp(0.0, _triggerDistance);
        final nextState = nextPull >= _triggerDistance
            ? ZhandeRefreshState.ready
            : ZhandeRefreshState.pulling;
        if (_refreshState == ZhandeRefreshState.pulling &&
            nextState == ZhandeRefreshState.ready) {
          _bounceController..reset()..forward();
          _glowController..reset()..forward();
        }
        debugPrint(
            '_ZhandeRefresh: Overscroll pull=$nextPull state=$nextState');
        setState(() {
          _pullDistance = nextPull;
          _refreshState = nextState;
        });
      }
    } else if (notification is ScrollEndNotification && _pullDistance > 0) {
      if (_isClosing) return false;
      if (_pullDistance >= _triggerDistance) {
        _startRefresh();
      } else {
        _startClosing();
      }
    }
    return false;
  }

  // ── State transitions ──

  void _startRefresh() {
    debugPrint('_ZhandeRefresh: Refreshing start');
    setState(() {
      _pullDistance = _triggerDistance;
      _refreshState = ZhandeRefreshState.refreshing;
    });
    _breathingController.repeat(reverse: true);
    widget.onRefresh().then((_) {
      debugPrint('_ZhandeRefresh: onRefresh complete -> Success');
      if (!mounted) return;
      _breathingController.stop();
      _glowController.reset();
      setState(() {
        if (widget.enableSuccessText) {
          if (_random.nextDouble() < 0.1 &&
              kZhandeCompleteMessages.length > 5) {
            _completeMessageIndex = kZhandeCompleteMessages.length - 1;
          } else {
            _completeMessageIndex =
                _random.nextInt(kZhandeCompleteMessages.length - 1);
          }
        } else {
          _completeMessageIndex = 0;
        }
        _refreshState = ZhandeRefreshState.success;
      });
      debugPrint(
          '_ZhandeRefresh: Success message=${kZhandeCompleteMessages[_completeMessageIndex]}');
      Future.delayed(widget.successDuration, () {
        if (!mounted) return;
        debugPrint('_ZhandeRefresh: Success -> Closing');
        _startClosing();
      });
    }).catchError((error) {
      debugPrint('_ZhandeRefresh: onRefresh error: $error');
      if (!mounted) return;
      _breathingController.stop();
      _glowController.reset();
      setState(() {
        _completeMessageIndex =
            _random.nextInt(kZhandeCompleteMessages.length - 1);
        _refreshState = ZhandeRefreshState.success;
      });
      Future.delayed(widget.successDuration, () {
        if (!mounted) return;
        _startClosing();
      });
    });
  }

  void _startClosing() {
    debugPrint('_ZhandeRefresh: startClosing pullDistance=$_pullDistance');
    if (_pullDistance <= 0) {
      setState(() {
        _refreshState = ZhandeRefreshState.idle;
      });
      return;
    }
    final startFrom =
        (_pullDistance / _triggerDistance).clamp(0.0, 1.0);
    _closeController.value = startFrom;
    setState(() {
      _refreshState = ZhandeRefreshState.closing;
    });
    _closeController.reverse();
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final headerHeight = _headerHeight;
    final showHeader = headerHeight > 0;
    final textProgress = (_isRefreshing || _isSuccess)
        ? 1.0
        : (headerHeight / _triggerDistance).clamp(0.0, 1.0);
    final textScale =
        kZhandeTextScaleMin + ((kZhandeTextScaleMax - kZhandeTextScaleMin) * textProgress);
    final successOpacity = _isSuccess ? 1.0 : 0.0;
    final showContent = headerHeight >= kZhandeContentMinHeight;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScroll,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Shifted content
          AnimatedContainer(
            duration: _isClosing
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, headerHeight, 0),
            child: widget.child,
          ),
          // Header overlay
          if (showHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedContainer(
                  height: headerHeight,
                  duration: _isClosing
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  color: Colors.white,
                  clipBehavior: Clip.hardEdge,
                  child: showContent
                      ? Center(
                          child: AnimatedBuilder(
                            animation: Listenable.merge([
                              _bounceScale,
                              _breathingScale,
                              _breathingOpacity,
                              _glowController,
                            ]),
                            builder: (context, _) {
                              return ZhandeRefreshHeader(
                                textProgress: textProgress,
                                textScale: textScale,
                                successOpacity: successOpacity,
                                bounceScale: _bounceScale.value,
                                breathingScale: _breathingScale.value,
                                breathingOpacity: _breathingOpacity.value,
                                glowValue: _glowController.value,
                                isRefreshing: _isRefreshing,
                                isSuccess: _isSuccess,
                                completeMessage:
                                    kZhandeCompleteMessages[
                                        _completeMessageIndex],
                              );
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


