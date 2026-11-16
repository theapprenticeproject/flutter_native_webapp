/// The student's initials, from a name: the first letter of the first and the
/// last word (for example "Durva Sibling" is "DS"). The Gallery shows initials
/// only, never the name (R-85).
///
/// shortcut: the first character of a word is its first code point. A Hindi
/// letter with a mark on it may lose the mark. Use grapheme clusters when
/// that matters.
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return '?';
  String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();
  final list = words.toList();
  return list.length == 1
      ? first(list.first)
      : first(list.first) + first(list.last);
}

/// One piece of other students' work in the Gallery. Only valid work comes here
/// (R-59). It shows the initials, not the name.
class GalleryItem {
  const GalleryItem({
    required this.submissionId,
    required this.initials,
    required this.isVideo,
    required this.url,
  });

  final String submissionId;
  final String initials;
  final bool isVideo;

  /// A short-lived signed link to the file in R2.
  final String url;

  factory GalleryItem.fromJson(Map<String, dynamic> json) => GalleryItem(
    submissionId: (json['submission_id'] ?? json['key'] ?? '') as String,
    initials: initialsOf((json['display_name'] as String?) ?? ''),
    isVideo: json['media_type'] == 'video',
    url: (json['url'] as String?) ?? '',
  );
}

/// One page of the Gallery.
class GalleryPage {
  const GalleryPage({required this.items, required this.cursor});

  final List<GalleryItem> items;

  /// Ask for the next page with this. Null: there is no more.
  final String? cursor;

  bool get hasMore => cursor != null && cursor!.isNotEmpty;
}
