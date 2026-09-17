class PricingPolicy {
  final int graceSeconds;
  final int firstHourCents;
  final int extraHourCents;

  const PricingPolicy({
    this.graceSeconds = 15 * 60,
    this.firstHourCents = 1000,
    this.extraHourCents = 500,
  });

  void validate() {
    if (graceSeconds < 0 ||
        graceSeconds > 3600 ||
        firstHourCents < 0 ||
        extraHourCents < 0) {
      throw ArgumentError('Tarifa inválida');
    }
  }
}

int calculateCostCents({
  required DateTime entry,
  required DateTime exit,
  int graceSeconds = 15 * 60,
  int firstHourCents = 1000,
  int extraHourCents = 500,
}) {
  final policy = PricingPolicy(
    graceSeconds: graceSeconds,
    firstHourCents: firstHourCents,
    extraHourCents: extraHourCents,
  )..validate();
  final elapsed = exit.toUtc().difference(entry.toUtc());
  if (elapsed.isNegative) {
    throw ArgumentError('Saída anterior à entrada');
  }

  final micros = elapsed.inMicroseconds;
  final graceMicros = policy.graceSeconds * Duration.microsecondsPerSecond;
  const hourMicros = 60 * 60 * Duration.microsecondsPerSecond;
  if (micros <= graceMicros) return 0;
  if (micros <= hourMicros) return policy.firstHourCents;

  final extraMicros = micros - hourMicros;
  final startedHours = (extraMicros + hourMicros - 1) ~/ hourMicros;
  return policy.firstHourCents + startedHours * policy.extraHourCents;
}
