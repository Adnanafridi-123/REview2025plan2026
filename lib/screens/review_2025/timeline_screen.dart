import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _selectedFilter = 'All';
  int? _expandedMonth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),
              
              // Content
              Expanded(
                child: Consumer<AppProvider>(
                  builder: (context, provider, _) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      children: [
                        // Header with icon
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF598BFF).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('📅', style: TextStyle(fontSize: 22)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timeline',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  'Your 2025 journey month by month',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Summary Stats Row - 3 cards
                        _buildSummaryStats(provider),
                        const SizedBox(height: 16),
                        
                        // Filter Tabs
                        _buildFilterTabs(),
                        const SizedBox(height: 16),
                        
                        // Month Cards
                        ...List.generate(12, (index) {
                          final month = 12 - index;
                          return _buildMonthCard(context, provider, month);
                        }),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats(AppProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            emoji: '📷',
            count: provider.totalPhotos,
            label: 'Photos',
            color: const Color(0xFFFF5E62),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '🎬',
            count: provider.totalVideos,
            label: 'Videos',
            color: const Color(0xFF00C9FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            emoji: '📝',
            count: provider.totalJournals,
            label: 'Journals',
            color: const Color(0xFFFC6767),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Photos', 'Videos', 'Journals'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF8C52FF)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF666666),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthCard(BuildContext context, AppProvider provider, int month) {
    final monthName = DateFormat('MMMM').format(DateTime(2025, month));
    final isExpanded = _expandedMonth == month;
    
    // Get counts for this month
    final photoCount = provider.photos.where((p) => p.date.month == month).length;
    final videoCount = provider.videos.where((v) => v.date.month == month).length;
    final journalCount = provider.journals2025.where((j) => j.date.month == month).length;
    final hasContent = photoCount > 0 || videoCount > 0 || journalCount > 0;
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _expandedMonth = isExpanded ? null : month;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Month Number Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasContent 
                        ? const Color(0xFF8C52FF).withValues(alpha: 0.1)
                        : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      month.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasContent ? const Color(0xFF8C52FF) : const Color(0xFF999999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Month Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: hasContent ? const Color(0xFF333333) : const Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Data Pills
                      Row(
                        children: [
                          if (photoCount > 0)
                            _DataPill(count: photoCount, color: const Color(0xFFFF5E62)),
                          if (videoCount > 0)
                            _DataPill(count: videoCount, color: const Color(0xFF00C9FF)),
                          if (journalCount > 0)
                            _DataPill(count: journalCount, color: const Color(0xFFFC6767)),
                          if (!hasContent)
                            Text(
                              'No entries',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Expand Arrow
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: hasContent ? const Color(0xFF8C52FF) : const Color(0xFFCCCCCC),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded Content
        if (isExpanded)
          _buildExpandedContent(context, provider, month, photoCount, videoCount, journalCount),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context, AppProvider provider, int month, int photoCount, int videoCount, int journalCount) {
    final monthName = DateFormat('MMMM').format(DateTime(2025, month));
    final photos = provider.photos.where((p) => p.date.month == month).toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Add Section
          Text(
            'Quick Add to $monthName',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickAddButton(
                emoji: '📷',
                label: 'Photo',
                color: const Color(0xFFFF5E62),
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _QuickAddButton(
                emoji: '🎬',
                label: 'Video',
                color: const Color(0xFF00C9FF),
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _QuickAddButton(
                emoji: '📝',
                label: 'Journal',
                color: const Color(0xFFFC6767),
                onTap: () {},
              ),
            ],
          ),
          
          // Photos Preview
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Photos ($photoCount)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photos[index].path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.photo, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String emoji;
  final int count;
  final String label;
  final Color color;

  const _StatCard({
    required this.emoji,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Pill Widget
class _DataPill extends StatelessWidget {
  final int count;
  final Color color;

  const _DataPill({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count.toString(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// Quick Add Button Widget
class _QuickAddButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
