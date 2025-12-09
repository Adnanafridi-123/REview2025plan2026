import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/vision_board_item.dart';
import '../../widgets/beautiful_back_button.dart';

class VisionBoardScreen extends StatefulWidget {
  const VisionBoardScreen({super.key});

  @override
  State<VisionBoardScreen> createState() => _VisionBoardScreenState();
}

class _VisionBoardScreenState extends State<VisionBoardScreen> {
  late Box<VisionBoardItem> _visionBox;
  String _selectedCategory = 'All';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': '🌟', 'color': Color(0xFF8C52FF)},
    {'name': 'Career', 'icon': '💼', 'color': Color(0xFF4CAF50)},
    {'name': 'Health', 'icon': '🏃', 'color': Color(0xFFFF5722)},
    {'name': 'Family', 'icon': '👨‍👩‍👧‍👦', 'color': Color(0xFFE91E63)},
    {'name': 'Travel', 'icon': '✈️', 'color': Color(0xFF2196F3)},
    {'name': 'Finance', 'icon': '💰', 'color': Color(0xFFFFC107)},
    {'name': 'Personal', 'icon': '🎯', 'color': Color(0xFF9C27B0)},
  ];

  final List<String> _inspirationalQuotes = [
    "Dream big, start small, act now.",
    "Your only limit is your mind.",
    "Make it happen!",
    "Believe in yourself.",
    "Success is a journey, not a destination.",
    "Stay focused, go after your dreams.",
    "The future belongs to those who believe.",
    "Work hard, dream big.",
  ];

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(VisionBoardItemAdapter());
    }
    _visionBox = await Hive.openBox<VisionBoardItem>('vision_board');
    setState(() => _isLoading = false);
  }

  List<VisionBoardItem> get _filteredItems {
    final items = _visionBox.values.toList();
    if (_selectedCategory == 'All') return items;
    return items.where((i) => i.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildCategoryFilter(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _buildVisionBoard(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVisionDialog(),
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Color(0xFF8C52FF)),
        label: const Text('Add Dream', style: TextStyle(color: Color(0xFF8C52FF), fontWeight: FontWeight.bold)),
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
                  'Vision Board 2026',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Apne khwab visualize karein',
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
            child: const Text('📌', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat['name']),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(cat['icon'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      color: isSelected ? cat['color'] : Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _buildVisionBoard() {
    final items = _filteredItems;
    
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Apna pehla dream add karein!',
              style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Vision board se apne goals visualize hon ge',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildVisionCard(items[index]),
    );
  }

  Widget _buildVisionCard(VisionBoardItem item) {
    final catData = _categories.firstWhere(
      (c) => c['name'] == item.category,
      orElse: () => _categories[0],
    );

    return GestureDetector(
      onTap: () => _showVisionDetails(item),
      onLongPress: () => _showDeleteDialog(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or Placeholder
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: (catData['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: item.imagePath != null && File(item.imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.file(
                          File(item.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Text(
                          catData['icon'],
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
              ),
            ),
            // Content
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (catData['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: TextStyle(
                          fontSize: 10,
                          color: catData['color'] as Color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Quote
                    if (item.quote != null)
                      Text(
                        '"${item.quote}"',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            // Completion indicator
            if (item.isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Achieved!', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddVisionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Personal';
    String selectedQuote = _inspirationalQuotes[0];
    String? imagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Add New Dream',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    
                    // Image Picker
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() => imagePath = image.path);
                        }
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                        ),
                        child: imagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(File(imagePath!), fit: BoxFit.cover, width: double.infinity),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Add Vision Image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Dream Title',
                        hintText: 'e.g., Visit Paris, Start Business',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.stars),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category
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
                    const SizedBox(height: 16),
                    
                    // Quote Selector
                    const Text('Motivational Quote', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedQuote,
                          isExpanded: true,
                          items: _inspirationalQuotes.map((q) => DropdownMenuItem(
                            value: q,
                            child: Text('"$q"', style: const TextStyle(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => setModalState(() => selectedQuote = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Add Button
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) return;
                        
                        final item = VisionBoardItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          description: descController.text.isNotEmpty ? descController.text : null,
                          imagePath: imagePath,
                          category: selectedCategory,
                          quote: selectedQuote,
                          createdAt: DateTime.now(),
                        );
                        
                        _visionBox.add(item);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8C52FF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add to Vision Board', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  void _showVisionDetails(VisionBoardItem item) {
    final catData = _categories.firstWhere((c) => c['name'] == item.category, orElse: () => _categories[0]);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (catData['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(catData['icon'], style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(item.category, style: TextStyle(color: catData['color'] as Color)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (item.description != null)
              Text(item.description!, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            if (item.quote != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💭', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('"${item.quote}"', style: const TextStyle(fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      item.isCompleted = !item.isCompleted;
                      item.save();
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon: Icon(item.isCompleted ? Icons.undo : Icons.check_circle),
                    label: Text(item.isCompleted ? 'Mark Pending' : 'Mark Achieved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.isCompleted ? Colors.grey : const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(VisionBoardItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Dream?'),
        content: Text('Kya aap "${item.title}" ko delete karna chahte hain?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              item.delete();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
