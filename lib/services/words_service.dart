import 'dart:convert';
import 'package:dictionary_app/models/dictionary_model.dart';
import 'package:http/http.dart' as http;

class WordsService {
  static const String baseUrl = 'https://nubbdictapi.kode4u.tech/';
  static const Duration timeoutDuration = Duration(seconds: 30);
  
  static final http.Client _client = http.Client();

  // Get all common English words (A-Z starter words)
  static Future<List<DictionaryEntry>> getAllWords() async {
    print('📚 Loading all words...');
    
    // Common English words starting with each letter
    final starterWords = [
      'a', 'ability', 'able', 'about', 'above', 'accept', 'according', 
      'account', 'across', 'act', 'action', 'activity', 'actually',
      'b', 'baby', 'back', 'bad', 'bag', 'ball', 'bank', 'base', 'be',
      'bear', 'beat', 'beautiful', 'because', 'become', 'bed', 'been',
      'c', 'call', 'camera', 'can', 'car', 'card', 'care', 'carry',
      'case', 'cat', 'catch', 'cause', 'cell', 'center', 'central',
      'd', 'dad', 'daily', 'dance', 'dark', 'data', 'date', 'day',
      'dead', 'deal', 'death', 'decade', 'decide', 'decision', 'deep',
      'e', 'each', 'early', 'east', 'easy', 'eat', 'economic', 'edge',
      'education', 'effect', 'effort', 'eight', 'either', 'election',
      'f', 'face', 'fact', 'factor', 'fail', 'fall', 'family', 'far',
      'fast', 'father', 'fear', 'federal', 'feel', 'feeling', 'few',
      'g', 'game', 'garden', 'gas', 'general', 'generation', 'get',
      'girl', 'give', 'glass', 'go', 'goal', 'good', 'government',
      'h', 'hair', 'half', 'hand', 'hang', 'happen', 'happy', 'hard',
      'have', 'he', 'head', 'health', 'hear', 'heart', 'heat', 'heavy',
      'i', 'idea', 'identify', 'if', 'image', 'imagine', 'impact',
      'important', 'improve', 'in', 'include', 'including', 'increase',
      'j', 'job', 'join', 'journey', 'joy', 'judge', 'jump', 'just',
      'k', 'keep', 'key', 'kid', 'kill', 'kind', 'king', 'kitchen',
      'know', 'knowledge',
      'l', 'lab', 'land', 'language', 'large', 'last', 'late', 'later',
      'laugh', 'law', 'lead', 'leader', 'learn', 'least', 'leave',
      'm', 'machine', 'magazine', 'main', 'major', 'make', 'man',
      'manage', 'manager', 'many', 'market', 'marriage', 'material',
      'n', 'name', 'nation', 'national', 'natural', 'nature', 'near',
      'nearly', 'necessary', 'need', 'network', 'never', 'new', 'news',
      'o', 'occur', 'of', 'off', 'offer', 'office', 'officer', 'official',
      'often', 'oh', 'oil', 'ok', 'old', 'on', 'once', 'one',
      'p', 'page', 'pain', 'paint', 'paper', 'parent', 'part', 'participant',
      'particular', 'particularly', 'partner', 'party', 'pass', 'past',
      'q', 'quality', 'question', 'quick', 'quickly', 'quiet', 'quite',
      'r', 'race', 'radio', 'raise', 'range', 'rate', 'rather', 'reach',
      'read', 'ready', 'real', 'reality', 'realize', 'really', 'reason',
      's', 'say', 'scene', 'school', 'science', 'scientist', 'score',
      'sea', 'season', 'seat', 'second', 'section', 'security', 'see',
      't', 'table', 'take', 'talk', 'task', 'tax', 'teach', 'teacher',
      'team', 'technology', 'television', 'tell', 'ten', 'tend', 'term',
      'u', 'under', 'understand', 'unit', 'university', 'until', 'up',
      'upon', 'us', 'use', 'usually',
      'v', 'value', 'various', 'very', 'victim', 'view', 'violence',
      'visit', 'voice', 'vote',
      'w', 'wait', 'walk', 'wall', 'want', 'war', 'watch', 'water',
      'way', 'we', 'weapon', 'wear', 'week', 'weight', 'well', 'west',
      'x', 'x-ray',
      'y', 'year', 'yes', 'yet', 'you', 'young', 'your',
      'z', 'zero', 'zone'
    ];

    List<DictionaryEntry> allEntries = [];
    Set<String> uniqueWords = {};

    // Load each starter word
    for (final word in starterWords) {
      try {
        final results = await _searchWord(word);
        
        for (final entry in results) {
          final lowerWord = entry.englishWord.toLowerCase();
          if (!uniqueWords.contains(lowerWord)) {
            uniqueWords.add(lowerWord);
            allEntries.add(entry);
          }
        }
        
        // Small delay to avoid overwhelming the API
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        print('⚠️ Error loading word "$word": $e');
      }
    }

    // Sort alphabetically
    allEntries.sort((a, b) => a.englishWord
        .toLowerCase()
        .compareTo(b.englishWord.toLowerCase()));

    print('✅ Loaded ${allEntries.length} unique words');
    return allEntries;
  }

  static Future<List<DictionaryEntry>> _searchWord(String query) async {
    final url = Uri.parse('${baseUrl}search?query=${Uri.encodeQueryComponent(query)}');
    
    try {
      final response = await _client
          .get(url)
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List dictionarys = jsonData['dictionarys'] ?? [];
        
        return dictionarys
            .map((e) => DictionaryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Get words by letter (for better organization)
  static Future<Map<String, List<DictionaryEntry>>> getWordsByLetter() async {
    final allWords = await getAllWords();
    final Map<String, List<DictionaryEntry>> wordsByLetter = {};
    
    for (final entry in allWords) {
      if (entry.englishWord.isEmpty) continue;
      
      final firstLetter = entry.englishWord[0].toUpperCase();
      
      if (!wordsByLetter.containsKey(firstLetter)) {
        wordsByLetter[firstLetter] = [];
      }
      
      wordsByLetter[firstLetter]!.add(entry);
    }
    
    // Sort each list alphabetically
    wordsByLetter.forEach((letter, words) {
      words.sort((a, b) => a.englishWord
          .toLowerCase()
          .compareTo(b.englishWord.toLowerCase()));
    });
    
    return wordsByLetter;
  }
}