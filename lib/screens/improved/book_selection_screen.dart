import 'package:flutter/material.dart';
import 'package:english_learning_app/models/book_model.dart';
import 'package:english_learning_app/constants/book_constants.dart';

class BookSelectionScreen extends StatefulWidget {
  final List<Book> books;
  final Function(Book) onBookSelected;

  const BookSelectionScreen({
    Key? key,
    required this.books,
    required this.onBookSelected,
  }) : super(key: key);

  @override
  State<BookSelectionScreen> createState() => _BookSelectionScreenState();
}

class _BookSelectionScreenState extends State<BookSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, List<Book>> _booksBySeries = {};

  @override
  void initState() {
    super.initState();
    _groupBooksBySeries();
    _tabController = TabController(
      length: _booksBySeries.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _groupBooksBySeries() {
    _booksBySeries.clear();
    for (final book in widget.books) {
      final series = BookConstants.getBookSeries(book.id);
      if (!_booksBySeries.containsKey(series)) {
        _booksBySeries[series] = [];
      }
      _booksBySeries[series]!.add(book);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇教材'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: _booksBySeries.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _booksBySeries.entries
                    .map((entry) => Tab(
                          text: '${BookConstants.seriesNames[entry.key]} 系列',
                        ))
                    .toList(),
              )
            : null,
      ),
      body: _booksBySeries.length == 1
          ? _buildBookGrid(_booksBySeries.values.first)
          : TabBarView(
              controller: _tabController,
              children: _booksBySeries.values
                  .map((books) => _buildBookGrid(books))
                  .toList(),
            ),
    );
  }

  Widget _buildBookGrid(List<Book> books) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildBookCard(book);
        },
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          widget.onBookSelected(book);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 封面圖片
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  BookConstants.getBookCoverPath(book.id),
                  fit: BoxFit.cover,
                  alignment: Alignment.centerRight,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: BookConstants.getBookColor(book.id).withValues(alpha: 0.2),
                    child: Icon(
                      Icons.book,
                      color: BookConstants.getBookColor(book.id),
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
            
            // 教材資訊
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.id,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 