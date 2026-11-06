/// v5 returns this object directly, without a `result` wrapper.
class CheckResult {
  const CheckResult({required this.available});
  final bool available;

  factory CheckResult.fromJson(Map<String, dynamic> json) =>
      CheckResult(available: json['available'] as bool);
}
