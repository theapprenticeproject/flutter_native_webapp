class FlowManifestFileEntry {
  const FlowManifestFileEntry({required this.languages});
  final List<String> languages;

  bool hasLanguage(String code) => languages.contains(code);

  factory FlowManifestFileEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['languages'];
    final languages = raw is List
        ? raw.whereType<String>().toList()
        : <String>[];
    return FlowManifestFileEntry(languages: languages);
  }

  Map<String, dynamic> toJson() => {'languages': languages};
}

class FlowManifest {
  const FlowManifest({required this.categories});
  final Map<String, Map<String, FlowManifestFileEntry>> categories;

  FlowManifestFileEntry? entryFor(String category, String fileName) =>
      categories[category]?[fileName];

  String resolveLanguage(
    String category,
    String fileName,
    String requestedLanguage,
  ) {
    final entry = entryFor(category, fileName);
    if (entry != null && entry.hasLanguage(requestedLanguage)) {
      return requestedLanguage;
    }
    return 'en';
  }

  List<String> fileNamesFor(String category) =>
      categories[category]?.keys.toList() ?? const [];

  List<String> allCategories() => categories.keys.toList();

  factory FlowManifest.fromJson(Map<String, dynamic> json) {
    final flows = json['flows'];
    final categories = <String, Map<String, FlowManifestFileEntry>>{};
    if (flows is Map) {
      flows.forEach((category, files) {
        if (files is Map) {
          final fileMap = <String, FlowManifestFileEntry>{};
          files.forEach((fileName, entry) {
            if (entry is Map) {
              fileMap[fileName.toString()] = FlowManifestFileEntry.fromJson(
                Map<String, dynamic>.from(entry),
              );
            }
          });
          categories[category.toString()] = fileMap;
        }
      });
    }
    return FlowManifest(categories: categories);
  }

  Map<String, dynamic> toJson() => {
    'flows': categories.map(
      (category, files) => MapEntry(
        category,
        files.map((fileName, entry) => MapEntry(fileName, entry.toJson())),
      ),
    ),
  };
}
