import 'package:flutter/material.dart';

class AppTheme {
  // ==========================================
  // MAIN APP BACKGROUND - Vibrant Purple/Blue Gradient (EXACT from screenshot)
  // ==========================================
  static const Color bgTop = Color(0xFF5B4B9E);      // Vibrant Purple
  static const Color bgMiddle = Color(0xFF7B6BC4);   // Medium Purple
  static const Color bgBottom = Color(0xFF9B8BD4);   // Light Purple
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgTop, bgMiddle, bgBottom],
    stops: [0.0, 0.5, 1.0],
  );

  // ==========================================
  // HOME SCREEN - Hero Cards (VIBRANT from screenshot)
  // ==========================================
  
  // Review 2025 Card - Vibrant Pink/Coral Gradient (EXACT from screenshot)
  static const LinearGradient review2025Gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFE8A0B5), Color(0xFFF5C5D0)],
  );
  
  // Plan 2026 Card - Vibrant Teal/Mint Gradient (EXACT from screenshot)
  static const LinearGradient plan2026Gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4ECDC4), Color(0xFF7BDDC8)],
  );
  
  // Quick Stats Card - Vibrant Glass Purple
  static const Color quickStatsGlass = Color(0xFF7C6CC8);
  
  // Quick Actions Card - Vibrant Dark Purple Glass
  static const Color quickActionsGlass = Color(0xFF5B4B9E);

  // ==========================================
  // QUICK STAT CARD COLORS (VIBRANT from screenshot)
  // ==========================================
  static const Color statPhotos = Color(0xFFFF6B8A);      // Vibrant Pink
  static const Color statVideos = Color(0xFF4ECDC4);      // Vibrant Teal
  static const Color statJournal = Color(0xFFFFB347);     // Vibrant Orange
  static const Color statAchievements = Color(0xFF4CD964); // Vibrant Green

  // ==========================================
  // REVIEW 2025 MENU - Card Gradients (VIBRANT)
  // ==========================================
  
  // 1. Timeline - Vibrant Purple/Blue
  static const LinearGradient timelineGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
  );
  
  // 2. Photos - Vibrant Pink/Blue
  static const LinearGradient photosGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF6B8A), Color(0xFF6A82FB)],
  );
  
  // 3. Videos - Vibrant Teal/Green
  static const LinearGradient videosGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
  );
  
  // 4. Journal - Vibrant Orange/Pink
  static const LinearGradient journalGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFF512F), Color(0xFFDD2476)],
  );
  
  // 5. Screenshots - Vibrant Orange/Yellow
  static const LinearGradient screenshotsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFF2994A), Color(0xFFF2C94C)],
  );
  
  // 6. Achievements - Vibrant Yellow/Gold
  static const LinearGradient achievementsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFD200), Color(0xFFF7971E)],
  );
  
  // 7. Statistics - Vibrant Green/Teal
  static const LinearGradient statisticsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00B09B), Color(0xFF96C93D)],
  );
  
  // 8. Generate Wrapped - Vibrant Purple/Deep Blue
  static const LinearGradient wrappedGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
  );
  
  // 9. Video Memories - Vibrant Dark Blue/Purple
  static const LinearGradient videoMemoriesGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF24243E), Color(0xFF302B63)],
  );

  // ==========================================
  // PLAN 2026 MENU - Card Gradients (VIBRANT)
  // ==========================================
  
  // 1. Goals - Vibrant Purple to Red/Orange
  static const LinearGradient goalsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF9C6DFF), Color(0xFFFF6B6B)],
  );
  
  // 2. Habits - Vibrant Cyan to Teal
  static const LinearGradient habitsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4DD0E1), Color(0xFF4DB6AC)],
  );
  
  // 3. Calendar - Vibrant Orange to Deep Orange
  static const LinearGradient calendarGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFFB74D), Color(0xFFFF8A65)],
  );
  
  // 4. Analytics - Vibrant Teal to Dark Teal
  static const LinearGradient analyticsGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
  );
  
  // 5. Badges - Vibrant Yellow to Gold
  static const LinearGradient badgesGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFFDD835), Color(0xFFFBC02D)],
  );
  
  // 6. Weekly Review - Vibrant Pink to Magenta
  static const LinearGradient weeklyReviewGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFEC407A), Color(0xFFD81B60)],
  );

  // ==========================================
  // QUICK ACTION ICON COLORS (VIBRANT from screenshot)
  // ==========================================
  static const Color iconPink = Color(0xFFFF6B8A);      // Vibrant Pink
  static const Color iconGreen = Color(0xFF4CD964);     // Vibrant Green
  static const Color iconOrange = Color(0xFFFFB347);    // Vibrant Orange
  static const Color iconBlue = Color(0xFF5AC8FA);      // Vibrant Blue
  static const Color iconRed = Color(0xFFFF6B6B);       // Vibrant Red
  static const Color iconPurple = Color(0xFF7C6CC8);    // Vibrant Purple
  static const Color iconTeal = Color(0xFF4ECDC4);      // Vibrant Teal

  // ==========================================
  // TEXT COLORS (VIBRANT)
  // ==========================================
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE0E0E0);
  static const Color textYellow = Color(0xFFFFEB3B);    // Bright Yellow title
  static const Color textDark = Color(0xFF2D2D2D);

  // ==========================================
  // CARD STYLING
  // ==========================================
  static const double cardBorderRadius = 20.0;
  static const double menuCardHeight = 85.0;
  static const double screenPadding = 20.0;
  static const double cardSpacing = 16.0;
  static const double iconSize = 32.0;

  // ==========================================
  // COMPATIBILITY - Card Gradient Aliases
  // ==========================================
  static const LinearGradient goalsCardGradient = goalsGradient;
  static const LinearGradient habitsCardGradient = habitsGradient;
  static const LinearGradient calendarCardGradient = calendarGradient;
  static const LinearGradient analyticsCardGradient = analyticsGradient;
  static const LinearGradient badgesCardGradient = badgesGradient;
  static const LinearGradient weeklyReviewCardGradient = weeklyReviewGradient;
  static const LinearGradient weeklyCardGradient = weeklyReviewGradient;
  static const LinearGradient journalCardGradient = journalGradient;
  static const LinearGradient achievementsCardGradient = achievementsGradient;
  static const LinearGradient statisticsCardGradient = statisticsGradient;
  static const LinearGradient screenshotsCardGradient = screenshotsGradient;
  static const LinearGradient timelineCardGradient = timelineGradient;
  static const LinearGradient photosCardGradient = photosGradient;
  static const LinearGradient videosCardGradient = videosGradient;
  
  // Individual color starts/ends for gradients
  static const Color goalsStart = Color(0xFF9C6DFF);
  static const Color goalsEnd = Color(0xFFFF6B6B);
  static const Color habitsStart = Color(0xFF4DD0E1);
  static const Color habitsEnd = Color(0xFF4DB6AC);
  static const Color calendarStart = Color(0xFFFFB74D);
  static const Color calendarEnd = Color(0xFFFF8A65);
  static const Color analyticsStart = Color(0xFF4DB6AC);
  static const Color analyticsEnd = Color(0xFF26A69A);
  static const Color badgesStart = Color(0xFFFDD835);
  static const Color badgesEnd = Color(0xFFFBC02D);
  static const Color weeklyReviewStart = Color(0xFFEC407A);
  static const Color weeklyReviewEnd = Color(0xFFD81B60);
  static const Color weeklyStart = Color(0xFFEC407A);
  static const Color weeklyEnd = Color(0xFFD81B60);
  static const Color journalStart = Color(0xFFFF512F);
  static const Color journalEnd = Color(0xFFDD2476);
  static const Color achievementsStart = Color(0xFFFFD200);
  static const Color achievementsEnd = Color(0xFFF7971E);
  static const Color statisticsStart = Color(0xFF00B09B);
  static const Color statisticsEnd = Color(0xFF96C93D);
  static const Color screenshotsStart = Color(0xFFF2994A);
  static const Color screenshotsEnd = Color(0xFFF2C94C);
  static const Color timelineStart = Color(0xFF667EEA);
  static const Color timelineEnd = Color(0xFF764BA2);
  static const Color photosStart = Color(0xFFFF6B8A);
  static const Color photosEnd = Color(0xFF6A82FB);
  static const Color videosStart = Color(0xFF11998E);
  static const Color videosEnd = Color(0xFF38EF7D);
  
  // Primary colors (VIBRANT)
  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color primaryGreen = Color(0xFF00C853);
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color primaryTeal = Color(0xFF009688);
  static const Color primaryPink = Color(0xFFE91E63);
  
  // Accent Colors (VIBRANT)
  static const Color accentGreen = Color(0xFF4CD964);
  static const Color accentBlue = Color(0xFF5AC8FA);
  static const Color accentPink = Color(0xFFFF6B8A);
  static const Color accentOrange = Color(0xFFFFB347);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentPurple = Color(0xFF7C6CC8);
  
  // Text Colors Extended
  static const Color textPurple = Color(0xFF7C6CC8);
  static const Color titleYellow = Color(0xFFFFEB3B);
  
  // Background alias
  static const Color backgroundTop = bgTop;
  static const Color backgroundMiddle = bgMiddle;
  static const Color backgroundBottom = bgBottom;
  
  // Category colors map (VIBRANT)
  static const Map<String, Color> categoryColors = {
    'Health': Color(0xFF4CD964),
    'Career': Color(0xFF7C4DFF),
    'Finance': Color(0xFFFFB347),
    'Personal': Color(0xFFFF6B8A),
    'Learning': Color(0xFF5AC8FA),
    'Relationships': Color(0xFFFF6B6B),
  };
  
  // Mood colors (VIBRANT)
  static const Color moodHappy = Color(0xFF4CD964);
  static const Color moodSad = Color(0xFF5AC8FA);
  static const Color moodAngry = Color(0xFFFF6B6B);
  static const Color moodNeutral = Color(0xFFFFB347);
  static const Color moodLove = Color(0xFFFF6B8A);
  
  // Stats card background
  static const Color statsCardBg = Color(0xFF7C6CC8);

  // ==========================================
  // THEME DATA
  // ==========================================
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: bgTop,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Poppins',
      colorScheme: ColorScheme.fromSeed(
        seedColor: bgTop,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textWhite),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
    );
  }
}

// ==========================================
// GRADIENT BACKGROUND WIDGET
// ==========================================
class GradientBackground extends StatelessWidget {
  final Widget child;
  
  const GradientBackground({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: child,
    );
  }
}

// ==========================================
// GLASS CARD WIDGET (for glassmorphism effect)
// ==========================================
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double opacity;
  final EdgeInsets? padding;
  final double? borderRadius;
  
  const GlassCard({
    super.key,
    required this.child,
    this.color,
    this.opacity = 0.2,
    this.padding,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius ?? AppTheme.cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
