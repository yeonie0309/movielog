import 'dart:math' as math;

/// Preserves input order; the caller converts per-item errors to values.
Future<List<R>> mapBounded<T, R>(
  List<T> values,
  Future<R> Function(T) transform, {
  int concurrency = 5,
}) async {
  if (concurrency < 1) throw ArgumentError.value(concurrency);
  final results = List<R?>.filled(values.length, null);
  var next = 0;
  await Future.wait(
    List.generate(math.min(concurrency, values.length), (_) async {
      while (next < values.length) {
        final index = next++;
        results[index] = await transform(values[index]);
      }
    }),
  );
  return results.cast<R>();
}
