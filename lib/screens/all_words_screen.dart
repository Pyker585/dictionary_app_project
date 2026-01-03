import 'package:flutter/material.dart';
import 'package:dictionary_app/models/dictionary_model.dart';
import 'package:dictionary_app/services/words_service.dart';

class AllWordsScreen extends StatefulWidget {
  const AllWordsScreen({super.key});

  @override
  State<AllWordsScreen> createState() => _AllWordsScreenState();
}

class _AllWordsScreenState extends State<AllWordsScreen> {
  List<DictionaryEntry> allWords = [];
  List<DictionaryEntry> filteredWords = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllWords();
  }

  Future<void> _loadAllWords() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final words = await WordsService.getAllWords();
      
      if (words.isEmpty) {
        throw Exception('No words found. Please check your internet connection.');
      }

      setState(() {
        allWords = words;
        filteredWords = words;
        isLoading = false;
      });
      
      print('✅ Loaded ${words.length} words successfully');
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'មិនអាចផ្ទុកពាក្យបានទេ។ សូមព្យាយាមម្តងទៀត។';
      });
      print('❌ Error loading words: $e');
    }
  }

  void _filterWords(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredWords = allWords;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredWords = allWords
          .where((entry) {
            final word = entry.englishWord.toLowerCase();
            final definition = entry.khmerDef.toLowerCase();
            return word.contains(lowerQuery) || definition.contains(lowerQuery);
          })
          .toList();
    });
  }

  void _onSearchChanged(String value) {
    _filterWords(value);
  }

  void _clearSearch() {
    _searchController.clear();
    _filterWords('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ពាក្យទាំងអស់'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllWords,
            tooltip: 'ផ្ទុកឡើងវិញ',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: const InputDecoration(
                        hintText: 'ស្វែងរកពាក្យ...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),
          ),
          
          // Results count
          if (!isLoading && !hasError)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'សរុប: ${filteredWords.length} ពាក្យ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    Text(
                      'ស្វែងរក: "${_searchController.text}"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoading();
    }

    if (hasError) {
      return _buildError();
    }

    if (filteredWords.isEmpty) {
      return _buildNoResults();
    }

    return _buildWordList();
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'កំពុងផ្ទុកពាក្យទាំងអស់...',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'នេះអាចចំណាយពេលរយៈពេលខ្លះ',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAllWords,
            child: Text('ព្យាយាមម្តងទៀត'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('ត្រលប់ទៅទំព័រដើម'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'មិនរកឃើញពាក្យទេ',
            style: TextStyle(color: Colors.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isNotEmpty)
            Text(
              'សម្រាប់: "${_searchController.text}"',
              style: TextStyle(color: Colors.grey[600]),
            ),
          const SizedBox(height: 8),
          Text(
            'សូមព្យាយាមពាក្យផ្សេងទៀត',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _clearSearch,
            child: Text('ស្វែងរកឡើងវិញ'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordList() {
    return ListView.builder(
      itemCount: filteredWords.length,
      padding: EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final entry = filteredWords[index];
        return _buildWordItem(entry, index);
      },
    );
  }

  Widget _buildWordItem(DictionaryEntry entry, int index) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word and part of speech
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.capitalizedEnglishWord,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
                if (entry.partOfSpeech.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPartOfSpeechColor(entry.partOfSpeech),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.partOfSpeech.toLowerCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Pronunciation
            if (entry.englishPhonetic.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.volume_up, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    entry.englishPhonetic,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 12),
            
            // Khmer definition
            Text(
              entry.cleanKhmerDef,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${entry.englishWord}" to favorites'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.share, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Share "${entry.englishWord}"'),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, size: 20),
                  onPressed: () {
                    _showWordDetail(entry);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPartOfSpeechColor(String pos) {
    final lowerPos = pos.toLowerCase();
    
    if (lowerPos.contains('noun')) return Colors.blue;
    if (lowerPos.contains('verb')) return Colors.green;
    if (lowerPos.contains('adjective')) return Colors.orange;
    if (lowerPos.contains('adverb')) return Colors.purple;
    if (lowerPos.contains('pronoun')) return Colors.pink;
    if (lowerPos.contains('preposition')) return Colors.brown;
    if (lowerPos.contains('conjunction')) return Colors.teal;
    if (lowerPos.contains('interjection')) return Colors.red;
    
    return Colors.grey;
  }

  void _showWordDetail(DictionaryEntry entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.capitalizedEnglishWord,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (entry.partOfSpeech.isNotEmpty)
                Chip(
                  label: Text(
                    entry.partOfSpeech.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: _getPartOfSpeechColor(entry.partOfSpeech),
                ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.englishPhonetic.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pronunciation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.volume_up, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            entry.englishPhonetic,
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                
                if (entry.khmerPhonetic.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'អានថា:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.khmerPhonetic,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                
                Text(
                  'និយមន័យ:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.cleanKhmerDef,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('បិទ'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Add to favorites
              },
              child: Text('ចំណូលចិត្ត'),
            ),
          ],
        );
      },
    );
  }
}