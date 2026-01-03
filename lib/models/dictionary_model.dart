class DictionaryEntry {
  final int id;
  final String englishWord;
  final String partOfSpeech;
  final String englishPhonetic;
  final String khmerPhonetic;
  final String khmerDef;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DictionaryEntry({
    required this.id,
    required this.englishWord,
    required this.partOfSpeech,
    required this.englishPhonetic,
    required this.khmerPhonetic,
    required this.khmerDef,
    this.createdAt,
    this.updatedAt,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    return DictionaryEntry(
      id: _parseInt(json['id']),
      englishWord: _parseString(json['english_word']),
      partOfSpeech: _parseString(json['part_of_speech']),
      englishPhonetic: _parseString(json['english_phonetic']),
      khmerPhonetic: _parseString(json['khmer_phonetic']),
      khmerDef: _parseString(json['khmer_def']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'english_word': englishWord,
      'part_of_speech': partOfSpeech,
      'english_phonetic': englishPhonetic,
      'khmer_phonetic': khmerPhonetic,
      'khmer_def': khmerDef,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  String get cleanKhmerDef {
    return khmerDef.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  String get capitalizedEnglishWord {
    if (englishWord.isEmpty) return '';
    return englishWord[0].toUpperCase() + englishWord.substring(1);
  }

  bool get hasAudio => englishPhonetic.isNotEmpty;

  String get formattedPartOfSpeech {
    final pos = partOfSpeech.toLowerCase();
    return '($pos)';
  }

  DictionaryEntry copyWith({
    int? id,
    String? englishWord,
    String? partOfSpeech,
    String? englishPhonetic,
    String? khmerPhonetic,
    String? khmerDef,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DictionaryEntry(
      id: id ?? this.id,
      englishWord: englishWord ?? this.englishWord,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      englishPhonetic: englishPhonetic ?? this.englishPhonetic,
      khmerPhonetic: khmerPhonetic ?? this.khmerPhonetic,
      khmerDef: khmerDef ?? this.khmerDef,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DictionaryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DictionaryEntry{id: $id, englishWord: $englishWord, partOfSpeech: $partOfSpeech}';
  }

  // Helper methods
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static String _parseString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}

// Cache class
class DictionaryCache {
  static final Map<String, List<DictionaryEntry>> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration cacheDuration = Duration(hours: 1);

  static List<DictionaryEntry>? get(String query) {
    final key = query.toLowerCase();
    final timestamp = _cacheTimestamps[key];
    
    if (_cache.containsKey(key) && 
        timestamp != null && 
        DateTime.now().difference(timestamp) < cacheDuration) {
      return _cache[key];
    }
    return null;
  }

  static void set(String query, List<DictionaryEntry> results) {
    final key = query.toLowerCase();
    _cache[key] = results;
    _cacheTimestamps[key] = DateTime.now();
  }

  static void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}