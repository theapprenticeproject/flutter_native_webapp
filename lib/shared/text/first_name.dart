/// The first word of a student's name (the design says "Aarav", not the full
/// name, and "Congratulations Aarav!"). [fallback] when there is no name.
String firstName(String? name, {String fallback = 'Champ'}) {
  final first = (name ?? '').trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? fallback : first;
}
