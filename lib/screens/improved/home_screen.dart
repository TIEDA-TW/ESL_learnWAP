import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
// Ensure all necessary imports are present
import 'package:english_learning_app/models/book_model.dart';
import 'package:english_learning_app/services/storage_service.dart';
import 'package:english_learning_app/services/user_service_improved.dart';
import 'package:english_learning_app/services/game_service.dart';
import 'package:english_learning_app/widgets/improved/book_card.dart';
import 'package:english_learning_app/widgets/improved/activity_card.dart';
import 'package:english_learning_app/screens/improved/reader_screen.dart';
import 'package:english_learning_app/screens/games/game_menu_screen.dart';
// import 'package:english_learning_app/screens/flashcard_screen.dart'; // Original, might be replaced
import 'package:english_learning_app/screens/improved/vocabulary/improved_flashcard_screen.dart';
import 'package:english_learning_app/screens/improved/pronunciation/pronunciation_practice_screen.dart';
import 'package:english_learning_app/screens/improved/progress_screen.dart';
// import 'package:english_learning_app/screens/improved/improved_settings_screen.dart'; // This was the old settings screen
import 'package:english_learning_app/routes/app_routes.dart'; // For named routes
import 'package:english_learning_app/services/auth_service.dart'; // For username
import 'package:english_learning_app/constants/book_constants.dart';
import 'dart:convert'; // For json.decode in _debugAssets
// import 'package:english_learning_app/screens/settings_page.dart'; // Not needed if using named routes
import 'package:english_learning_app/screens/improved/book_selection_screen.dart';

class ImprovedHomeScreen extends StatefulWidget {
  const ImprovedHomeScreen({Key? key}) : super(key: key);

  @override
  State<ImprovedHomeScreen> createState() => _ImprovedHomeScreenState();
}

class _ImprovedHomeScreenState extends State<ImprovedHomeScreen> {
  List<Book> _books = [];
  
  late StorageService _storageService;
  late ImprovedUserService _userService;
  final AuthService _authService = AuthService(); // Add AuthService instance
  bool _isLoading = true;
  
  String? _userNameDisplay; // Updated to reflect its purpose for display
  // String? _loggedInUsername; // Can be merged or kept if used differently from _userName from UserService
  Map<String, int> _recentProgress = {};
  Map<String, int> _masteredWords = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _storageService = StorageService();
    _userService = ImprovedUserService(); // Keep for other user data if needed
    await _userService.initialize(); 
    await _loadUserData(); // This will now also fetch username via AuthService

    // Try loading books using various methods
    bool booksLoaded = false;
    try {
      print('Attempting to get complete book IDs...');
      final bookIds = await _storageService.getCompleteBookIds();
      print('Found ${bookIds.length} complete book IDs: ${bookIds.join(", ")}');
      if (bookIds.isNotEmpty) {
        _updateBooksState(bookIds);
        booksLoaded = true;
      }
    } catch (e) {
      print('Failed to get complete book IDs: $e');
    }

    if (!booksLoaded) {
      try {
        print('Attempting to get all valid book IDs...');
        final validBookIds = await _storageService.getAllValidBookIds();
        print('Found ${validBookIds.length} valid book IDs: ${validBookIds.join(", ")}');
        if (validBookIds.isNotEmpty) {
          _updateBooksState(validBookIds);
          booksLoaded = true;
        }
      } catch (e) {
        print('Failed to get all valid book IDs: $e');
      }
    }
    
    if (!booksLoaded) {
      print('Falling back to loading books from constants...');
      await _loadBooksFromConstants();
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateBooksState(List<String> bookIds) {
    final books = bookIds.map((id) => Book(
      id: id,
      name: BookConstants.getBookDisplayName(id),
      dataPath: BookConstants.getBookDataPath(id),
      imagePath: BookConstants.getBookImagePath(id),
      audioPath: BookConstants.getEnglishAudioPath(id),
    )).toList();
    
    setState(() {
      _books = books;
      _isLoading = false;
    });
  }
  
  Future<void> _loadBooksFromConstants() async {
    // This is the fallback if other methods fail
    final bookIds = BookConstants.enabledBooks;
    _updateBooksState(bookIds);
  }


  Future<void> _loadUserData() async {
    // Fetch username from AuthService
    _userNameDisplay = await _authService.getLoggedInUsername();
    
    // Load other user data from ImprovedUserService (progress, mastered words, etc.)
    // Example: if _userService had methods like these
    // _recentProgress = await _userService.getRecentProgress();
    // _masteredWords = await _userService.getMasteredWordCounts();

    // If _userNameDisplay is still null (e.g., if AuthService didn't find it),
    // you might want a fallback or default name.
    if (_userNameDisplay == null) {
      // Fallback to username from ImprovedUserService if it exists and is different
      String? userServiceName = await _userService.getUserName();
      if (userServiceName != null && userServiceName.isNotEmpty) {
        _userNameDisplay = userServiceName;
      } else {
        _userNameDisplay = 'Learner'; // Default display name
      }
    }
    
    if(mounted){
      setState(() {
        // All state updates are handled here
      });
    }
  }
  
  // This method might be redundant if _loadUserData handles username from AuthService
  // Future<void> _loadAuthUsername() async {
  //   final username = await _authService.getLoggedInUsername(); 
  //   if (mounted) {
  //     setState(() {
  //       _loggedInUsername = username; 
  //     });
  //   }
  // }

  void _debugAssets() async {
    try {
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final bookDataFiles = manifestMap.keys.where((key) => key.startsWith('assets/Book_data/')).toList();
      final bookFolders = manifestMap.keys.where((key) => key.startsWith('assets/Books/')).toList();
      
      print('==== Asset Debug Info ====');
      print('Book_data files:');
      bookDataFiles.forEach((file) => print('  - $file'));
      print('Books folders (any entry indicates presence):');
      bookFolders.map((folder) => folder.split('/')[2]).toSet().forEach((bookId) => print('  - assets/Books/$bookId/'));
      print('======================');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Asset list printed to console. Please check logs.'))
      );
    } catch (e) {
      print('Failed to debug assets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Asset debug failed: $e'))
      );
    }
  }
  
  void _openBook(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImprovedReaderScreen(book: book)),
    ).then((_) => _refreshData());
  }
  
  void _openGames() {
    if (_books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No books available for games.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameMenuScreen(book: _books.first, gameService: GameService())),
    ).then((_) => _refreshData());
  }
  
  void _openPronunciationPractice() {
    if (_books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No books available for pronunciation practice.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PronunciationPracticeScreen(book: _books.first)),
    );
  }

  void _openFlashcards() {
    if (_books.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No books available for flashcards.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ImprovedFlashcardScreen(bookId: _books.first.id)), // 使用動態 ID
    );
  }
  
  void _openProgress() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProgressScreen(books: _books)),
    );
  }
  
  Future<void> _refreshData() async {
    await _loadUserData(); // Reload user-specific data
  }
  
  void _navigateToSettings() { // Renamed from _openSettings
    Navigator.pushNamed(context, AppRoutes.settings);
  }
  
  // 讓舊代碼使用新方法名
  void _openSettings() {
    _navigateToSettings();
  }
  
  // 新增專門的教材選擇模態框方法
  void _showBookSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 允許控制高度
      backgroundColor: Colors.transparent, // 透明背景以便自定義樣式
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // 初始高度為螢幕的60%
        minChildSize: 0.3, // 最小高度為螢幕的30%
        maxChildSize: 0.9, // 最大高度為螢幕的90%
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 標題區域
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '選擇教材',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5), // 使用主題藍色，更明顯
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // 分隔線
              Divider(height: 1, color: Colors.grey[300]),
              
              // 可滾動的教材列表
              Expanded(
                child: _books.isEmpty 
                  ? const Center(
                      child: Text(
                        '暫無可用教材',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : _buildScrollableBookList(scrollController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 建立可滾動的教材列表
  Widget _buildScrollableBookList(ScrollController scrollController) {
    // 按系列分組教材
    final Map<String, List<Book>> booksBySeries = {};
    for (final book in _books) {
      final series = BookConstants.getBookSeries(book.id);
      if (!booksBySeries.containsKey(series)) {
        booksBySeries[series] = [];
      }
      booksBySeries[series]!.add(book);
    }
    
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 如果只有一個系列，直接顯示教材列表
        if (booksBySeries.length == 1)
          ...booksBySeries.values.first.map((book) => _buildBookListTile(book)),
        
        // 如果有多個系列，按系列分組顯示
        if (booksBySeries.length > 1)
          ...booksBySeries.entries.map((entry) => [
            // 系列標題
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Text(
                '${BookConstants.seriesNames[entry.key]} 系列',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            // 該系列的教材
            ...entry.value.map((book) => _buildBookListTile(book)),
          ]).expand((widgets) => widgets),
        
        // 底部間距
        const SizedBox(height: 16),
      ],
    );
  }

  // 建立教材列表項目
  Widget _buildBookListTile(Book book) {
    final progress = _recentProgress[book.id] ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 60,
            child: Image.asset(
              BookConstants.getBookCoverPath(book.id),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight, // 顯示圖片右半邊
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: BookConstants.getBookColor(book.id).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book,
                  color: BookConstants.getBookColor(book.id),
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          book.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '教材編號: ${book.id}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (progress > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '學習進度: $progress%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        BookConstants.getBookColor(book.id),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: BookConstants.getBookColor(book.id),
          size: 16,
        ),
        onTap: () {
          Navigator.pop(context);
          _openBook(book);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 首頁標題
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF43A047)], // Logo藍+綠
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/ESL Logo.png',
                    width: 60,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '台灣兒童美語協會ESL美語學習系統',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                  // 新增除錯按鈕
                  IconButton(
                    icon: Icon(Icons.bug_report, color: Colors.white),
                    onPressed: _debugAssets,
                    tooltip: '除錯資產文件',
                  ),
                ],
              ),
            ),
            
            // 主內容區域
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 書籍區域
                    const Text(
                      '我的教材',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DefaultTabController(
                      length: BookConstants.enabledSeries.length,
                      child: Column(
                        children: [
                          TabBar(
                            isScrollable: true,
                            labelColor: Colors.blue,
                            unselectedLabelColor: Colors.white,
                            tabs: BookConstants.enabledSeries.map((series) => Tab(
                              text: '${BookConstants.seriesNames[series]} 系列'
                            )).toList(),
                          ),
                          Column(
                            children: [
                              // 使用固定高度，與卡片尺寸匹配
                              SizedBox(
                                height: 200, // 固定高度，給卡片和邊距留出足夠空間
                                child: TabBarView(
                                  children: BookConstants.enabledSeries.map((series) =>
                                    _buildBookList(_books.where((b) => b.id.startsWith(series)).toList())
                                  ).toList(),
                                ),
                              ),
                              // 添加滾動提示
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.swipe, size: 14, color: Colors.grey[400]),
                                    SizedBox(width: 4),
                                    Text(
                                      '左右滑動查看更多教材',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 活動區域
                    const Text(
                      '學習活動',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ActivityCard(
                            title: '趣味遊戲',
                            description: '透過遊戲學習英語',
                            icon: Icons.games,
                            color: Colors.orange,
                            onTap: _openGames,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ActivityCard(
                            title: '學習進度',
                            description: '查看你的學習歷程',
                            icon: Icons.insights,
                            color: Colors.green,
                            onTap: _openProgress,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ActivityCard(
                            title: '單字卡片',
                            description: '複習學過的單字',
                            icon: Icons.style,
                            color: Colors.purple,
                            onTap: () {
                              // 使用第一本可用教材而非硬編碼 V1
                              final bookId = _books.isNotEmpty ? _books.first.id : BookConstants.defaultBookId;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImprovedFlashcardScreen(bookId: bookId),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ActivityCard(
                            title: '發音練習',
                            description: '加強英語發音',
                            icon: Icons.record_voice_over,
                            color: Colors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PronunciationPracticeScreen(book: _books.first),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // 首頁
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首頁',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: '教材',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games),
            label: '遊戲',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設置',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0: // 首頁
              break;
            case 1: // 教材頁面
              _showBookSelectionModal();
              break;
            case 2: // 遊戲頁面
              _openGames();
              break;
            case 3: // 設置頁面
              _openSettings();
              break;
          }
        },
      ),
    );
  }

  Widget _buildBookList(List<Book> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 改為固定尺寸策略，不再根據螢幕寬度動態調整
        // 統一使用固定寬度，避免在小螢幕上放大導致溢出
        double cardWidth = 140; // 固定卡片寬度
        
        // 如果沒有書籍，顯示提示
        if (books.isEmpty) {
          return Center(
            child: Text(
              '此系列暫無教材',
              style: TextStyle(color: Colors.grey[400]),
            ),
          );
        }
        
        // 添加滾動控制器，用於滾動指示與操作
        final ScrollController scrollController = ScrollController();
        
        // 計算是否需要滾動提示（如果書籍數量乘以卡片寬度加邊距超過容器寬度）
        bool needsScrollIndicator = books.length * (cardWidth + 16) > constraints.maxWidth;
        
        return Stack(
          children: [
            // 主要ListView
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ScrollConfiguration(
                // 自定義滾動行為，在所有平台上都顯示滾動條
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: true,
                  physics: const BouncingScrollPhysics(),
                  dragDevices: {
                    PointerDeviceKind.touch, 
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(), // 使用彈性滾動效果
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    final progress = _recentProgress[book.id] ?? 0;
                    return Container(
                      width: cardWidth,
                      margin: const EdgeInsets.only(right: 12), // 減少右側邊距
                      child: BookCard(
                        book: book,
                        progress: progress,
                        onTap: () => _openBook(book),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // 左側滾動提示
            if (needsScrollIndicator)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    // 向左滾動一個項目的寬度
                    scrollController.animateTo(
                      (scrollController.offset - cardWidth - 12).clamp(0, scrollController.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5), // 增加對比度
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_left,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            
            // 右側滾動提示
            if (needsScrollIndicator)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    // 向右滾動一個項目的寬度
                    scrollController.animateTo(
                      (scrollController.offset + cardWidth + 12).clamp(0, scrollController.position.maxScrollExtent),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Container(
                    width: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5), // 增加對比度
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}