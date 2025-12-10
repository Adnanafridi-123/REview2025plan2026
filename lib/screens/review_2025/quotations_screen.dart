import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/quote_item.dart';
import '../../widgets/beautiful_back_button.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  late Box<QuoteItem> _quotesBox;
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final GlobalKey _quoteKey = GlobalKey();
  int _currentQuoteIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': '✨', 'color': Color(0xFF8C52FF)},
    {'name': 'Maafi', 'icon': '🤲', 'color': Color(0xFF4CAF50)},
    {'name': 'Shukr', 'icon': '🙏', 'color': Color(0xFFFF9800)},
    {'name': 'Khushi', 'icon': '😊', 'color': Color(0xFFE91E63)},
    {'name': 'Dua', 'icon': '🤍', 'color': Color(0xFF2196F3)},
    {'name': 'Umeed', 'icon': '🌟', 'color': Color(0xFF9C27B0)},
    {'name': 'Mohabbat', 'icon': '❤️', 'color': Color(0xFFFF5722)},
    {'name': 'Custom', 'icon': '📝', 'color': Color(0xFF607D8B)},
  ];

  final List<List<Color>> _gradients = [
    [Color(0xFF667eea), Color(0xFF764ba2)],
    [Color(0xFF11998e), Color(0xFF38ef7d)],
    [Color(0xFFf857a6), Color(0xFFff5858)],
    [Color(0xFF00C9FF), Color(0xFF92FE9D)],
    [Color(0xFFFFA726), Color(0xFFFF7043)],
    [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    [Color(0xFF11998e), Color(0xFF38ef7d)],
  ];

  // Pre-defined quotes
  final List<Map<String, String>> _defaultQuotes = [
    // Maafi - Forgiveness
    {'text': 'Jo guzar gaya usay maaf karo, naya saal naye iraday lao', 'category': 'Maafi', 'author': ''},
    {'text': 'Maafi maangna kamzori nahi, himmat hai', 'category': 'Maafi', 'author': ''},
    {'text': 'Dil saaf rakhein, purani baatein bhool jaein', 'category': 'Maafi', 'author': ''},
    {'text': 'Ghaltiyan insaan se hoti hain, maaf karna farishton ka kaam hai', 'category': 'Maafi', 'author': ''},
    {'text': 'Is saal jo takleef di, maaf karo mujhe', 'category': 'Maafi', 'author': ''},
    {'text': 'Rishton mein maafi se bada koi tohfa nahi', 'category': 'Maafi', 'author': ''},
    {'text': 'Maafi do, maafi lo, khush raho', 'category': 'Maafi', 'author': ''},
    {'text': 'Dil se maaf karna seekho, zindagi asan ho jayegi', 'category': 'Maafi', 'author': ''},
    
    // Shukr - Gratitude
    {'text': 'Shukriya 2025, tune bahut kuch sikhaya', 'category': 'Shukr', 'author': ''},
    {'text': 'Har mushkil mein bhi Allah ka shukar', 'category': 'Shukr', 'author': ''},
    {'text': 'Jo mila uspe shukar, jo nahi mila uspe sabar', 'category': 'Shukr', 'author': ''},
    {'text': 'Shukr guzar insaan kabhi udas nahi rehta', 'category': 'Shukr', 'author': ''},
    {'text': 'Chhoti chhoti khushiyon ka shukar karo', 'category': 'Shukr', 'author': ''},
    {'text': 'Alhamdulillah har haal mein', 'category': 'Shukr', 'author': ''},
    {'text': 'Shukriya un sab ka jo is saal saath rahe', 'category': 'Shukr', 'author': ''},
    {'text': 'Zindagi mein jo bhi hai, shukar hai', 'category': 'Shukr', 'author': ''},
    
    // Khushi - Happiness
    {'text': 'Khush raho, khushiyan baanto', 'category': 'Khushi', 'author': ''},
    {'text': '2025 mein jo khushiyan mili, yaad rakhein', 'category': 'Khushi', 'author': ''},
    {'text': 'Muskurao, duniya tumhare saath muskurayegi', 'category': 'Khushi', 'author': ''},
    {'text': 'Khushi chhoti cheezon mein hai', 'category': 'Khushi', 'author': ''},
    {'text': 'Apni khushi khud banao', 'category': 'Khushi', 'author': ''},
    {'text': 'Khush woh jo doosron ko khush rakhe', 'category': 'Khushi', 'author': ''},
    {'text': 'Har din ek naya mauka hai khush rehne ka', 'category': 'Khushi', 'author': ''},
    {'text': 'Khushi dil mein ho to chehra khud muskurata hai', 'category': 'Khushi', 'author': ''},
    
    // Dua - Prayers
    {'text': 'Ya Allah, 2026 mein sab ko khush rakh', 'category': 'Dua', 'author': ''},
    {'text': 'Dua mein yaad rakhna', 'category': 'Dua', 'author': ''},
    {'text': 'Allah har mushkil asan farmaye', 'category': 'Dua', 'author': ''},
    {'text': 'Sab ki duaon ka asar ho', 'category': 'Dua', 'author': ''},
    {'text': 'Ya Rab, naye saal mein barkat de', 'category': 'Dua', 'author': ''},
    {'text': 'Dua karo, dua mango, dua dete raho', 'category': 'Dua', 'author': ''},
    {'text': 'Allah tamam masail hal farmaye', 'category': 'Dua', 'author': ''},
    {'text': 'Naye saal mein naya noor ho', 'category': 'Dua', 'author': ''},
    
    // Umeed - Hope
    {'text': '2026 mein sab acha hoga, InshaAllah', 'category': 'Umeed', 'author': ''},
    {'text': 'Umeed pe duniya qayam hai', 'category': 'Umeed', 'author': ''},
    {'text': 'Mushkilein aati hain, guzar bhi jaati hain', 'category': 'Umeed', 'author': ''},
    {'text': 'Naye saal, naye khwab, nayi umeedein', 'category': 'Umeed', 'author': ''},
    {'text': 'Haar mat mano, acha waqt aayega', 'category': 'Umeed', 'author': ''},
    {'text': 'Subah zaroor aayegi', 'category': 'Umeed', 'author': ''},
    {'text': 'Umeed ka daaman kabhi na chhodna', 'category': 'Umeed', 'author': ''},
    {'text': 'Aane wala kal behtar hoga', 'category': 'Umeed', 'author': ''},
    
    // Mohabbat - Love
    {'text': 'Mohabbat baanto, nafrat bhool jao', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Pyar se bado, pyar se jio', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Apnon se mohabbat, ghairon se izzat', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Dil mein mohabbat ho to duniya jannat hai', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Sab ko pyar do, pyar pao', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Rishte mohabbat se mazboot hote hain', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Mohabbat mein kamzori nahi, taqat hai', 'category': 'Mohabbat', 'author': ''},
    {'text': 'Pyar karo, pyar milega', 'category': 'Mohabbat', 'author': ''},
  ];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(QuoteItemAdapter());
    }
    _quotesBox = await Hive.openBox<QuoteItem>('quotes_2025');
    
    // Add default quotes if box is empty
    if (_quotesBox.isEmpty) {
      for (var q in _defaultQuotes) {
        final quote = QuoteItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + q['text']!.hashCode.toString(),
          text: q['text']!,
          category: q['category']!,
          author: q['author']!.isNotEmpty ? q['author'] : null,
          createdAt: DateTime.now(),
        );
        await _quotesBox.add(quote);
      }
    }
    
    setState(() => _isLoading = false);
  }

  List<QuoteItem> get _filteredQuotes {
    final quotes = _quotesBox.values.toList();
    if (_selectedCategory == 'All') return quotes;
    return quotes.where((q) => q.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradients[_currentQuoteIndex % _gradients.length],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _buildAppBar(),
                    _buildCategoryFilter(),
                    Expanded(child: _buildQuoteCards()),
                    _buildActionButtons(),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddQuoteDialog(),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF8C52FF)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const BeautifulBackButton(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quotations 2025',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Share karo, khushiyan baanto',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('💬', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() {
              _selectedCategory = cat['name'];
              _currentQuoteIndex = 0;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(cat['icon'], style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      color: isSelected ? cat['color'] : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuoteCards() {
    final quotes = _filteredQuotes;
    
    if (quotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💬', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Koi quote nahi mila',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Apna quote add karein',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      itemCount: quotes.length,
      onPageChanged: (index) => setState(() => _currentQuoteIndex = index),
      itemBuilder: (context, index) {
        final quote = quotes[index];
        return _buildQuoteCard(quote, index);
      },
    );
  }

  Widget _buildQuoteCard(QuoteItem quote, int index) {
    final catData = _categories.firstWhere(
      (c) => c['name'] == quote.category,
      orElse: () => _categories[0],
    );
    final gradient = _gradients[index % _gradients.length];

    return RepaintBoundary(
      key: index == _currentQuoteIndex ? _quoteKey : null,
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background Pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CustomPaint(
                  painter: _PatternPainter(),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(catData['icon'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          quote.category,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Quote Mark
                  Text(
                    '"',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.3),
                      height: 0.5,
                    ),
                  ),
                  
                  // Quote Text
                  Text(
                    quote.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Author
                  if (quote.author != null && quote.author!.isNotEmpty)
                    Text(
                      '— ${quote.author}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // 2025 Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('✨', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Text(
                          'Review 2025',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Page Indicator
                  Text(
                    '${_currentQuoteIndex + 1} / ${_filteredQuotes.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Favorite Button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  quote.isFavorite = !quote.isFavorite;
                  quote.save();
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    quote.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: quote.isFavorite ? Colors.red : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Row(
        children: [
          // Copy Button
          Expanded(
            child: _ActionButton(
              icon: Icons.copy,
              label: 'Copy',
              onTap: () => _copyQuote(),
            ),
          ),
          const SizedBox(width: 12),
          // Share Button
          Expanded(
            child: _ActionButton(
              icon: Icons.share,
              label: 'Share',
              onTap: () => _shareQuote(),
            ),
          ),
          const SizedBox(width: 12),
          // Share as Image
          Expanded(
            child: _ActionButton(
              icon: Icons.image,
              label: 'Status',
              onTap: () => _shareAsImage(),
            ),
          ),
        ],
      ),
    );
  }

  void _copyQuote() {
    if (_filteredQuotes.isEmpty) return;
    final quote = _filteredQuotes[_currentQuoteIndex];
    Clipboard.setData(ClipboardData(text: '${quote.text}\n\n— Review 2025'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied! ✅'), backgroundColor: Color(0xFF4CAF50)),
    );
  }

  void _shareQuote() {
    if (_filteredQuotes.isEmpty) return;
    final quote = _filteredQuotes[_currentQuoteIndex];
    Share.share('${quote.text}\n\n✨ Review 2025\n📱 Reflect & Plan App');
  }

  Future<void> _shareAsImage() async {
    if (_filteredQuotes.isEmpty) return;
    
    try {
      RenderRepaintBoundary boundary = _quoteKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '✨ Review 2025 - Reflect & Plan App',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Share failed. Please try again.')),
        );
      }
    }
  }

  void _showAddQuoteDialog() {
    final textController = TextEditingController();
    String selectedCategory = 'Custom';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text('Apna Quote Add Karein', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    TextField(
                      controller: textController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Quote',
                        hintText: 'Apna quote likhein...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.format_quote),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.skip(1).map((cat) {
                        final isSelected = selectedCategory == cat['name'];
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedCategory = cat['name']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? cat['color'] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(cat['icon']),
                                const SizedBox(width: 4),
                                Text(
                                  cat['name'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: () {
                        if (textController.text.isEmpty) return;
                        
                        final quote = QuoteItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          text: textController.text,
                          category: selectedCategory,
                          isCustom: true,
                          createdAt: DateTime.now(),
                        );
                        
                        _quotesBox.add(quote);
                        Navigator.pop(context);
                        setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Quote added! ✅'), backgroundColor: Color(0xFF4CAF50)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8C52FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add Quote', style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(size.width * (0.1 + i * 0.2), size.height * 0.2),
        30 + i * 10,
        paint,
      );
      canvas.drawCircle(
        Offset(size.width * (0.2 + i * 0.2), size.height * 0.8),
        20 + i * 8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
