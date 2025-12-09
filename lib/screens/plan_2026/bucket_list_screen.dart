import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bucket_list_item.dart';
import '../../widgets/beautiful_back_button.dart';

class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> with SingleTickerProviderStateMixin {
  late Box<BucketListItem> _bucketBox;
  late TabController _tabController;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Travel', 'icon': '✈️', 'color': Color(0xFF2196F3)},
    {'name': 'Experience', 'icon': '🎉', 'color': Color(0xFFE91E63)},
    {'name': 'Learning', 'icon': '📚', 'color': Color(0xFF9C27B0)},
    {'name': 'Adventure', 'icon': '🏔️', 'color': Color(0xFF4CAF50)},
    {'name': 'Personal', 'icon': '🎯', 'color': Color(0xFFFF9800)},
    {'name': 'Career', 'icon': '💼', 'color': Color(0xFF607D8B)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initHive();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(BucketListItemAdapter());
    }
    _bucketBox = await Hive.openBox<BucketListItem>('bucket_list');
    setState(() => _isLoading = false);
  }

  List<BucketListItem> get _pendingItems => 
      _bucketBox.values.where((i) => !i.isCompleted).toList();
  
  List<BucketListItem> get _completedItems => 
      _bucketBox.values.where((i) => i.isCompleted).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf857a6), Color(0xFFff5858)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  children: [
                    _buildAppBar(),
                    _buildStats(),
                    _buildTabs(),
                    Expanded(child: _buildTabContent()),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.white,
        icon: const Icon(Icons.add, color: Color(0xFFf857a6)),
        label: const Text('Add Dream', style: TextStyle(color: Color(0xFFf857a6), fontWeight: FontWeight.bold)),
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
                  'Bucket List 2026',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  'Zindagi ke khwab pooray karein',
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
            child: const Text('✨', style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(count: _bucketBox.length, label: 'Total', icon: '📋'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _StatItem(count: _pendingItems.length, label: 'Pending', icon: '⏳'),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _StatItem(count: _completedItems.length, label: 'Done', icon: '✅'),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFFf857a6),
        unselectedLabelColor: Colors.white,
        tabs: const [
          Tab(text: '⏳ Pending'),
          Tab(text: '✅ Completed'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildItemsList(_pendingItems, false),
        _buildItemsList(_completedItems, true),
      ],
    );
  }

  Widget _buildItemsList(List<BucketListItem> items, bool isCompleted) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isCompleted ? '🎉' : '✨', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              isCompleted ? 'Abhi tak kuch complete nahi hua' : 'Koi bucket list item nahi hai',
              style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted ? 'Apne dreams poore karein!' : 'Apne khwab add karein',
              style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildItemCard(items[index]),
    );
  }

  Widget _buildItemCard(BucketListItem item) {
    final catData = _categories.firstWhere(
      (c) => c['name'] == item.category,
      orElse: () => _categories[0],
    );

    return GestureDetector(
      onTap: () => _showItemDetails(item),
      onLongPress: () => _showDeleteDialog(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Image if exists
            if (item.imagePath != null && File(item.imagePath!).existsSync())
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.file(
                  File(item.imagePath!),
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (catData['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(item.icon, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 14),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                            color: item.isCompleted ? Colors.grey : const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (catData['color'] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category,
                                style: TextStyle(fontSize: 11, color: catData['color'] as Color),
                              ),
                            ),
                            if (item.location != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 2),
                              Text(item.location!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Complete Button
                  GestureDetector(
                    onTap: () => _toggleComplete(item),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.isCompleted 
                            ? const Color(0xFF4CAF50) 
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.isCompleted ? Icons.check : Icons.circle_outlined,
                        color: item.isCompleted ? Colors.white : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleComplete(BucketListItem item) async {
    if (!item.isCompleted) {
      // Ask for completion photo
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      item.isCompleted = true;
      item.completedAt = DateTime.now();
      if (image != null) {
        item.imagePath = image.path;
      }
      item.save();
      
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Text('🎉 '),
                Text('Mubarak ho! Ek aur khwab poora hua!'),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } else {
      item.isCompleted = false;
      item.completedAt = null;
      item.save();
      setState(() {});
    }
  }

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCategory = 'Travel';
    String selectedIcon = '✈️';

    final icons = ['✈️', '🎉', '📚', '🏔️', '🎯', '💼', '🌍', '🎸', '🏖️', '🎭', '🚀', '💪'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
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
                    const Text('Add to Bucket List', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // Icon Selector
                    const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: icons.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFf857a6) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: const Color(0xFFf857a6), width: 2) : null,
                            ),
                            child: Text(icon, style: const TextStyle(fontSize: 24)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Dream/Goal',
                        hintText: 'e.g., Visit Paris, Learn Guitar',
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
                    
                    // Location
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: 'Location (optional)',
                        hintText: 'e.g., Paris, France',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category
                    const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
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
                    
                    // Add Button
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isEmpty) return;
                        
                        final item = BucketListItem(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          description: descController.text.isNotEmpty ? descController.text : null,
                          category: selectedCategory,
                          createdAt: DateTime.now(),
                          icon: selectedIcon,
                          location: locationController.text.isNotEmpty ? locationController.text : null,
                        );
                        
                        _bucketBox.add(item);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf857a6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Add to Bucket List', style: TextStyle(fontSize: 16, color: Colors.white)),
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

  void _showItemDetails(BucketListItem item) {
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
                Text(item.icon, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(item.category, style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                if (item.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Done!', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            if (item.description != null) ...[
              const SizedBox(height: 16),
              Text(item.description!, style: TextStyle(color: Colors.grey[700])),
            ],
            if (item.location != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(item.location!, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleComplete(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: item.isCompleted ? Colors.grey : const Color(0xFF4CAF50),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                item.isCompleted ? 'Mark as Pending' : '✨ Mark as Complete',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BucketListItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
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

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final String icon;

  const _StatItem({required this.count, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}
