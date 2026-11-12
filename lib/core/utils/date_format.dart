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

/// Tiempo transcurrido de forma corta: "ahora", "hace 5 min", "hace 3 h",
/// "ayer" o la fecha.
String timeAgo(DateTime moment, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(moment);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays == 1) return 'ayer';
  if (diff.inDays < 7) return 'hace ${diff.inDays} días';
  return formatDate(moment);
}
