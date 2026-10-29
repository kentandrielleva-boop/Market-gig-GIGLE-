import 'dart:async';

/// Combines the latest value of two streams, emitting whenever either produces
/// a new value once both have emitted at least once.
///
/// Hand-rolled so we do not pull in rxdart just for this pattern.
Stream<R> combineLatest2<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A, B) combine,
) {
  A? latestA;
  B? latestB;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  final controller = StreamController<R>();

  void maybeEmit() {
    final a = latestA;
    final b = latestB;
    if (a == null || b == null || controller.isClosed) return;
    controller.add(combine(a, b));
  }

  subA = first.listen(
    (value) {
      latestA = value;
      maybeEmit();
    },
    onError: controller.addError,
    onDone: () => controller.close(),
  );
  subB = second.listen(
    (value) {
      latestB = value;
      maybeEmit();
    },
    onError: controller.addError,
    onDone: () => controller.close(),
  );
  controller.onCancel = () async {
    await subA?.cancel();
    await subB?.cancel();
  };

  return controller.stream;
}
