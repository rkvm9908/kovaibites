
List<String> imagesFromMap(Map<String, dynamic> m) {
  final l = (m['images'] as List?)?.whereType<String>().toList() ?? [];
  if (l.isNotEmpty) return l;
  final s = m['imageUrl'];
  return (s is String && s.isNotEmpty) ? [s] : [];
}