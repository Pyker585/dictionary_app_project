import 'dart:async';
import 'package:dictionary_app/screens/all_words_screen.dart';
import 'package:flutter/material.dart';
import 'package:dictionary_app/models/dictionary_model.dart';
import 'package:dictionary_app/services/api_service.dart';
import 'package:dictionary_app/services/auth_service.dart';
import 'package:dictionary_app/models/auth_model.dart';
import 'package:dictionary_app/screens/auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<DictionaryEntry> dictionarys = [];
  bool isLoading = false;
  bool hasSearched = false;
  User? currentUser;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String currentQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getCurrentUser();
    setState(() {
      currentUser = user;
    });
  }

  Future<void> _searchWord(String query) async {
  if (query.isEmpty || query.length < 2) {
    if (query.length == 1) {
      showInfoMessage(context, 'សូមបញ្ចូលយ៉ាងតិច ២ តួអក្សរ');
    }
    setState(() {
      dictionarys = [];
      hasSearched = false;
    });
    return;
  }

  setState(() {
    isLoading = true;
    currentQuery = query;
    hasSearched = true;
  });

  print('🔍 Starting search for: "$query"');

  try {
    final results = await ApiService.search(query);
    
    setState(() {
      dictionarys = results;
      isLoading = false;
    });
    
    print('✅ Search completed. Found ${results.length} results');
    
    if (results.isEmpty) {
      showInfoMessage(context, 'មិនរកឃើញពាក្យ "$query" ទេ');
    } else {
      showSuccessMessage(context, 'រកឃើញ ${results.length} លទ្ធផល');
    }
  } on ApiException catch (e) {
    setState(() {
      dictionarys = [];
      isLoading = false;
    });
    
    showErrorMessage(context, getApiErrorMessage(e, currentQuery));
    
    print('❌ Search error: ${e.message}');
  } catch (e) {
    setState(() {
      dictionarys = [];
      isLoading = false;
    });
    
    showErrorMessage(context, 'កំហុសមិនស្គាល់: $e');
    
    print('❌ Unknown error: $e');
  }
}

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    
    if (value.isEmpty) {
      setState(() {
        dictionarys = [];
        hasSearched = false;
      });
      return;
    }
    
    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      if (value.isNotEmpty && value.length >= 2) {
        _searchWord(value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      dictionarys = [];
      hasSearched = false;
      currentQuery = '';
    });
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ចាកចេញ'),
        content: Text('តើអ្នកពិតជាចង់ចាកចេញមែនទេ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ទេ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            child: Text('ចាកចេញ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Center(
          child: Text('វចនានុក្រម អងគ្លេស-ខ្មែរ'),
        ),
        actions: [
          if (currentUser != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') _logout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('ចាកចេញ', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    currentUser?.name.isNotEmpty == true 
                        ? currentUser!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
              icon: const Icon(Icons.login),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0), 
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      onSubmitted: _searchWord,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'ស្វែងរកពាក្យអង់គ្លេស...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: _clearSearch,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'កំពុងស្វែងរក "$currentQuery"...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (!hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'សូមបញ្ចូលពាក្យសម្រាប់ស្វែងរក',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'ឧទាហរណ៍: hello, thank you, computer',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _searchController.text = 'hello';
                _searchWord('hello');
              },
              child: Text('សាកល្បងពាក្យ "hello"'),
            ),
          ],
        ),
      );
    }

    if (dictionarys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'មិនរកឃើញពាក្យ "$currentQuery" ទេ',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'សូមព្យាយាមពាក្យផ្សេងទៀត',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (currentQuery.isNotEmpty) {
          await _searchWord(currentQuery);
        }
      },
      child: ListView.builder(
        itemCount: dictionarys.length,
        padding: EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final entry = dictionarys[index];
          return _buildDictionaryCard(entry);
        },
      ),
    );
  }

  Widget _buildDictionaryCard(DictionaryEntry entry) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.blue, width: 4)),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  entry.capitalizedEnglishWord,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              if (entry.hasAudio)
                IconButton(
                  icon: Icon(Icons.volume_up, color: Colors.blue),
                  onPressed: () {
                    // TODO: Add audio playback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Audio playback coming soon')),
                    );
                  },
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry.partOfSpeech.isNotEmpty) ...[
                Chip(
                  label: Text(
                    entry.partOfSpeech.toUpperCase(),
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                SizedBox(height: 8),
              ],
              if (entry.englishPhonetic.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.phonelink_ring, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      entry.englishPhonetic,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              if (entry.khmerPhonetic.isNotEmpty) ...[
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.translate, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      entry.khmerPhonetic,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 12),
              Text(
                entry.cleanKhmerDef,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite_border, size: 20),
                    onPressed: () {
                      // TODO: Add to favorites
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added to favorites')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.share, size: 20),
                    onPressed: () {
                      // TODO: Share word
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Share feature coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

 // In HomeScreen's bottom navigation bar, update:
Widget _buildBottomNavigationBar() {
  return BottomAppBar(
    child: Padding(
      padding: const EdgeInsets.all(6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.home,
            label: 'ទំព័រដើម',
            onPressed: () {
              // Already on home
            },
            isActive: true,
          ),
          _buildNavButton(
            icon: Icons.list,
            label: 'ពាក្យទាំងអស់',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllWordsScreen()),
              );
            },
          ),
          _buildNavButton(
            icon: Icons.favorite_border,
            label: 'ចំណូលចិត្ត',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Favorites coming soon')),
              );
            },
          ),
          _buildNavButton(
            icon: Icons.person,
            label: 'គណនី',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Profile coming soon')),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.blue : Colors.grey,
            size: 20,
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function for error messages
String getApiErrorMessage(ApiException e, String query) {
  switch (e.statusCode) {
    case 408:
      return 'សំណើរយូរពេក សូមព្យាយាមម្តងទៀត';
    case 400:
      return 'ពាក្យស្វែងរកមិនត្រឹមត្រូវ';
    case 404:
      return 'មិនរកឃើញពាក្យ "$query" ទេ';
    case 500:
      return 'មានបញ្ហានៅក្នុងម៉ាស៊ីនបម្រើ';
    default:
      return 'មានបញ្ហាក្នុងការស្វែងរក: ${e.message}';
  }
}