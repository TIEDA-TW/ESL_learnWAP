import 'package:flutter/material.dart';
import '../../../models/vocabulary_model.dart';
import '../../../services/improved/tts_service.dart';
import '../../../services/user_service.dart';
import '../../../widgets/improved/flashcard.dart';
import '../../../widgets/improved/progress_indicator.dart';
import '../../../widgets/speech_rate_button.dart';

class VocabularyScreen extends StatefulWidget {
  final String bookId;
  final String bookName;
  
  const VocabularyScreen({
    Key? key,
    required this.bookId,
    required this.bookName,
  }) : super(key: key);

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late UserService _userService;
  late TtsService _ttsService;
  
  List<VocabularyItem> _allWords = [];
  List<VocabularyItem> _filterWords = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  // 過濾選項
  bool _showOnlyUnmastered = false;
  String _categoryFilter = 'All';
  String _searchQuery = '';
  
  // 閃卡控制器
  final PageController _pageController = PageController();
  
  // TTS語速設定
  static const List<double> _speechRates = [0.5, 0.7, 1.0];
  static const List<String> _speechRateLabels = ['慢', '正常', '快'];
  int _speechRateIndex = 1; // 預設為 0.7 (正常)
  double get _speechRate => _speechRates[_speechRateIndex];
  
  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _ttsService = TtsService();
    _loadVocabulary();
  }
  
  Future<void> _loadVocabulary() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 載入詞彙數據
      final words = await VocabularyService().getVocabularyForBook(widget.bookId);
      
      // 載入用戶已掌握的單字
      final masteredWords = await _userService.getMasteredWords(widget.bookId);
      
      // 標記已掌握的單字
      for (var word in words) {
        if (masteredWords.contains(word.word)) {
          word.mastered = true;
        }
      }
      
      setState(() {
        _allWords = words;
        _filterWords = List.from(_allWords);
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      print('載入詞彙失敗: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('載入詞彙失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 應用過濾條件
  void _applyFilters() {
    List<VocabularyItem> filtered = List.from(_allWords);
    
    // 僅顯示未掌握的單字
    if (_showOnlyUnmastered) {
      filtered = filtered.where((word) => !word.mastered).toList();
    }
    
    // 按類別過濾
    if (_categoryFilter != 'All') {
      filtered = filtered.where((word) => word.category == _categoryFilter).toList();
    }
    
    // 按搜索詞過濾
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((word) => 
        word.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        word.translation.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    setState(() {
      _filterWords = filtered;
      _currentIndex = _filterWords.isEmpty ? 0 : _currentIndex.clamp(0, _filterWords.length - 1);
    });
  }
  
  // 標記單字為已掌握
  Future<void> _markWordAsMastered(VocabularyItem word) async {
    // 只處理未掌握的單字
    if (word.mastered) return;
    
    // 更新單字狀態
    setState(() {
      word.mastered = true;
    });
    
    // 保存到用戶數據
    await _userService.addMasteredWord(widget.bookId, word.word);
    
    // 提示用戶
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${word.word} 已添加到已掌握單字'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 單字語音播放（統一語速）
  Future<void> _playWordAudio(VocabularyItem word) async {
    try {
      await _ttsService.speak(word.word, rate: _speechRate);
    } catch (e) {
      print('播放單字發音失敗: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('播放發音失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 翻到下一頁
  void _nextWord() {
    if (_currentIndex < _filterWords.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // 翻到上一頁
  void _prevWord() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  // 顯示過濾選項
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '詞彙過濾',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // 難度過濾
                  const Text(
                    '類別',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Noun',
                        'Verb',
                        'Adjective',
                        'Adverb',
                        'Preposition',
                      ].map((category) => 
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: _categoryFilter == category,
                            onSelected: (selected) {
                              setModalState(() {
                                _categoryFilter = selected ? category : 'All';
                              });
                            },
                          ),
                        )
                      ).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 僅顯示未掌握的單字
                  CheckboxListTile(
                    title: const Text('只顯示未掌握的單字'),
                    value: _showOnlyUnmastered,
                    onChanged: (value) {
                      setModalState(() {
                        _showOnlyUnmastered = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 應用按鈕
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text('應用過濾'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.bookName} - 詞彙學習'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_filterWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${widget.bookName} - 詞彙學習'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterOptions,
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                '沒有找到符合條件的單字',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _categoryFilter = 'All';
                    _showOnlyUnmastered = false;
                    _searchQuery = '';
                  });
                  _applyFilters();
                },
                child: const Text('重置過濾條件'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName} - 詞彙學習'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
          // 新增語速切換按鈕
          SpeechRateButton(
            speechRates: _speechRates,
            speechRateLabels: _speechRateLabels,
            currentIndex: _speechRateIndex,
            onRateChanged: (index) {
              setState(() {
                _speechRateIndex = index;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: VocabularySearchDelegate(
                  allWords: _allWords,
                  onWordSelected: (word) {
                    // 找到單字在過濾後列表中的索引
                    final index = _filterWords.indexWhere((w) => w.word == word.word);
                    if (index != -1) {
                      setState(() {
                        _currentIndex = index;
                      });
                      _pageController.jumpToPage(index);
                    }
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 進度指示器
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '進度: ${_currentIndex + 1} / ${_filterWords.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '掌握: ${_allWords.where((w) => w.mastered).length} / ${_allWords.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CustomProgressIndicator(
                  value: (_currentIndex + 1) / _filterWords.length,
                  backgroundColor: Colors.grey.shade200,
                  progressColor: Colors.blue,
                  height: 8,
                ),
              ],
            ),
          ),
          
          // 單字卡片
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _filterWords.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final word = _filterWords[index];
                return FlashCard(
                  word: word,
                  onPlayAudio: () => _playWordAudio(word),
                  onMarkMastered: () => _markWordAsMastered(word),
                );
              },
            ),
          ),
          
          // 導航按鈕
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _currentIndex > 0 ? _prevWord : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('上一個'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _currentIndex < _filterWords.length - 1 ? _nextWord : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('下一個'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 搜索委託
class VocabularySearchDelegate extends SearchDelegate<VocabularyItem> {
  final List<VocabularyItem> allWords;
  final Function(VocabularyItem) onWordSelected;
  
  VocabularySearchDelegate({
    required this.allWords,
    required this.onWordSelected,
  });
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, allWords.first);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }
  
  Widget _buildSearchResults() {
    final filteredWords = query.isEmpty
        ? allWords
        : allWords.where((word) => 
            word.word.toLowerCase().contains(query.toLowerCase()) ||
            word.translation.toLowerCase().contains(query.toLowerCase())
          ).toList();
    
    return ListView.builder(
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        final word = filteredWords[index];
        return ListTile(
          title: Text(word.word),
          subtitle: Text(word.translation),
          trailing: Icon(
            word.mastered ? Icons.check_circle : Icons.circle_outlined,
            color: word.mastered ? Colors.green : Colors.grey,
          ),
          onTap: () {
            close(context, word);
            onWordSelected(word);
          },
        );
      },
    );
  }
}