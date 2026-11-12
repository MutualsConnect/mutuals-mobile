const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// "11 nov 2026"
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// Días desde [d] hasta hoy, como texto: "hoy", "ayer" o "hace 3 días".
String daysAgo(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final diff = DateTime(
    today.year,
    today.month,
    today.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff <= 0) return 'hoy';
  if (diff == 1) return 'ayer';
  return 'hace $diff días';
}
