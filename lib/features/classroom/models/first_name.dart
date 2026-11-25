/// The first word of the student's name (the design says "Congratulations
/// Aarav!", not the full name). "Champ" when there is no name.
String firstName(String name) {
  final first = name.trim().split(RegExp(r'\s+')).first;
  return first.isEmpty ? 'Champ' : first;
}
