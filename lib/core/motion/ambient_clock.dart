import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_gig/core/motion/motion_tokens.dart';

/// Whether ambient motion (animated mesh, patches, hub rings) runs.
///
/// Settings hook only — no settings UI in this pass. [AmbientMotion.off]
/// freezes every ambient painter at its t=0 frame.
enum AmbientMotion { auto, off }

/// Shared motion switch, default [AmbientMotion.auto].
final ambientMotionProvider = StateProvider<AmbientMotion>(
  (_) => AmbientMotion.auto,
);

/// What a painter needs from the ambient clock: two repaint signals and a
/// paint-time seconds getter. Painters NEVER rebuild widgets — they pass
/// [fast]/[slow] to `CustomPainter(repaint:)` (the SDK attaches
/// `markNeedsPaint` straight to the listenable) and read [seconds] inside
/// `paint()`.
@immutable
class MotionRead {
  const MotionRead({
    required this.fast,
    required this.slow,
    required this.seconds,
  });

  /// 60fps repaint signal (patches, hub rings).
  final Listenable fast;

  /// Throttled repaint signal for the full-screen mesh (30fps by default —
  /// see [MotionTokens.meshTickDivisor]).
  final Listenable slow;

  /// Monotonic clock seconds at paint time; 0 while motion is frozen.
  final double Function() seconds;

  static double _zero() => 0;
  static final ChangeNotifier _silent = ChangeNotifier();

  /// Static t=0 frame: never notifies, reports 0s. Used for reduce-motion,
  /// off route, disabled motion, or when no clock is mounted (tests).
  static final MotionRead still = MotionRead(
    fast: _silent,
    slow: _silent,
    seconds: _zero,
  );
}

/// ONE shared clock for the whole app: a single [Ticker] drives two gated
/// notifiers (60fps + throttled). A raw [Ticker] with monotonic accumulation
/// (not `AnimationController(duration: 1 hour)..repeat()`) so time never
/// wraps and causes a visible phase jump.
///
/// Lifecycle:
/// * Ticker runs only while at least one painter is subscribed AND the app
///   is resumed AND [ambientMotionProvider] is [AmbientMotion.auto].
/// * Consumers receive [MotionRead.still] (t=0, no subscriptions) when
///   reduce-motion is on, [TickerMode] is off, or their route is covered —
///   the listener count then drops to 0 and the ticker stops.
/// * Provider off → seconds reset to 0 (one final static repaint), ticker
///   stopped. App backgrounded → ticker paused, seconds preserved.
typedef _TickerFactory = Ticker Function(TickerCallback onTick);

/// [ChangeNotifier] that reports its first/last subscriber so the clock can
/// start/stop the ticker with demand.
class _GatedNotifier extends ChangeNotifier {
  _GatedNotifier(this._onActive);

  final void Function(bool active) _onActive;
  bool _active = false;

  bool get isActive => _active;

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (!_active) {
      _active = true;
      _onActive(true);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (_active && !hasListeners) {
      _active = false;
      _onActive(false);
    }
  }

  /// Fire one repaint without rebuilding any widget.
  void fire() => notifyListeners();

  @override
  void dispose() {
    if (_active) {
      _active = false;
      _onActive(false);
    }
    super.dispose();
  }
}

class _MotionCore {
  _MotionCore(this._createTicker);

  final _TickerFactory _createTicker;

  late final _GatedNotifier _fast = _GatedNotifier(_onActive);
  late final _GatedNotifier _slow = _GatedNotifier(_onActive);
  late final MotionRead read = MotionRead(
    fast: _fast,
    slow: _slow,
    seconds: () => _seconds,
  );

  Ticker? _ticker;
  Duration? _lastTick;
  double _seconds = 0;
  bool _modeOn = true;
  bool _resumed = true;
  bool _disposed = false;
  int _frame = 0;

  bool get _wantRun => _fast.isActive || _slow.isActive;
  bool get _canRun => _modeOn && _resumed;

  void _onActive(bool _) => _reevaluate();

  void setMode(AmbientMotion mode) {
    final on = mode == AmbientMotion.auto;
    if (on == _modeOn) return;
    _modeOn = on;
    if (!on) _seconds = 0; // frozen frame must be t=0
    _reevaluate();
    // One final repaint so painters settle on the t=0 frame.
    if (!on && _wantRun) _fast.fire();
  }

  void setResumed(bool resumed) {
    if (resumed == _resumed) return;
    _resumed = resumed;
    _reevaluate(); // pause keeps _seconds; resume continues seamlessly
  }

  void _reevaluate() {
    if (_disposed) return;
    if (_canRun && _wantRun) {
      _start();
    } else {
      _stop();
    }
  }

  void _start() {
    if (_ticker != null && _ticker!.isActive) return;
    _lastTick = null;
    (_ticker ??= _createTicker(_onTick)).start();
  }

  void _stop() {
    if (_ticker == null || !_ticker!.isActive) return;
    _ticker!.stop();
    _lastTick = null;
  }

  void _onTick(Duration elapsed) {
    final last = _lastTick;
    _lastTick = elapsed;
    if (last == null) return; // baseline the delta
    final dt = (elapsed - last).inMicroseconds / 1e6;
    if (dt <= 0) return;
    _seconds += dt;
    _frame++;
    _fast.fire();
    if (_frame % MotionTokens.meshTickDivisor == 0) _slow.fire();
  }

  void dispose() {
    _disposed = true;
    _stop();
    _ticker?.dispose();
    _fast.dispose();
    _slow.dispose();
  }
}

/// App-root widget that owns the single ambient [Ticker] and publishes the
/// shared model through an [InheritedWidget] (plain, never notifies — so
/// consumers don't rebuild per frame). Place above `MaterialApp`.
class AmbientClock extends ConsumerStatefulWidget {
  const AmbientClock({super.key, required this.child});

  final Widget child;

  /// Repaint signals for painters built in [context].
  ///
  /// Returns [MotionRead.still] (static t=0 frame, no subscriptions → the
  /// shared ticker stays stopped) when: reduce-motion is on, [TickerMode]
  /// is off, the route is covered (not current), or no clock is mounted.
  static MotionRead motionOf(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return MotionRead.still;
    if (!TickerMode.valuesOf(context).enabled) return MotionRead.still;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return MotionRead.still;
    final model = _AmbientClockScope.maybeOf(context);
    if (model == null) return MotionRead.still;
    return model.read;
  }

  @override
  ConsumerState<AmbientClock> createState() => _AmbientClockState();
}

class _AmbientClockState extends ConsumerState<AmbientClock>
    with WidgetsBindingObserver {
  late final _MotionCore _core;

  @override
  void initState() {
    super.initState();
    _core = _MotionCore((onTick) => Ticker(onTick));
    _core.setMode(ref.read(ambientMotionProvider));
    _core.setResumed(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _core.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _core.setResumed(state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ambientMotionProvider, (_, next) => _core.setMode(next));
    return _AmbientClockScope(model: _core, child: widget.child);
  }
}

class _AmbientClockScope extends InheritedWidget {
  const _AmbientClockScope({required this.model, required super.child});

  final _MotionCore model;

  static _MotionCore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AmbientClockScope>()?.model;

  @override
  bool updateShouldNotify(_AmbientClockScope oldWidget) =>
      model != oldWidget.model;
}
