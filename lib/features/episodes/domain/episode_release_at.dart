String? releaseAtLocalToRpcPayload(DateTime? localDateTime) {
  if (localDateTime == null) {
    return null;
  }

  return localDateTime.toUtc().toIso8601String();
}

DateTime? releaseAtUtcToLocal(DateTime? utcDateTime) {
  return utcDateTime?.toLocal();
}

String formatEpisodeDateTime(DateTime? utcDateTime) {
  if (utcDateTime == null) {
    return '—';
  }

  final local = utcDateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$day.$month.$year $hour:$minute';
}
