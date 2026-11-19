/// Organizer reliability (0–5) as shown in the UI; «—» when nobody rated yet.
String formatReliability(double? value) =>
    value?.toStringAsFixed(1).replaceAll('.', ',') ?? '—';
