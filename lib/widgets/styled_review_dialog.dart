import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';
import '../services/review_service.dart';

class StyledReviewDialog extends StatefulWidget {
  const StyledReviewDialog({super.key});

  @override
  State<StyledReviewDialog> createState() => _StyledReviewDialogState();
}

class _StyledReviewDialogState extends State<StyledReviewDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _starAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _starAnimation;
  
  int _selectedStars = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _starAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starAnimationController, curve: Curves.bounceOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _starAnimationController.dispose();
    super.dispose();
  }

  Future<void> _requestReview() async {
    setState(() => _isSubmitting = true);
    
    try {
      await ReviewService().requestReview();
      
      if (mounted) {
        Navigator.of(context).pop(true);
        _showThankYouSnackBar();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showThankYouSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Thank you for your feedback! ❤️'),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text('Unable to open review. Please try again later.'),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _onStarTap(int stars) {
    setState(() => _selectedStars = stars);
    _starAnimationController.forward().then((_) {
      _starAnimationController.reverse();
    });
  }

  Widget _buildStar(int index) {
    final isSelected = index < _selectedStars;
    final isHovered = index == _selectedStars - 1;
    
    return GestureDetector(
      onTap: () => _onStarTap(index + 1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isSelected ? Icons.star : Icons.star_border,
          size: isHovered ? 40 : 35,
          color: isSelected 
              ? const Color(0xFFFFD700) 
              : Colors.grey.shade400,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return BackdropFilter(
          filter: ColorFilter.mode(
            Colors.black.withOpacity(0.5 * _fadeAnimation.value),
            BlendMode.srcOver,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        const Color(0xFFF8F9FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        'Enjoying JOB2DAY?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Your feedback helps us improve and helps others discover great jobs!',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Star rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) => _buildStar(index)),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Rating text
                      Text(
                        _selectedStars == 0 
                            ? 'Tap to rate'
                            : _selectedStars == 1 
                                ? 'Poor'
                                : _selectedStars == 2 
                                    ? 'Fair'
                                    : _selectedStars == 3 
                                        ? 'Good'
                                        : _selectedStars == 4 
                                            ? 'Very Good'
                                            : 'Excellent!',
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedStars >= 4 
                              ? AppColors.success 
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildButton(
                              text: 'Not Now',
                              onPressed: () => Navigator.of(context).pop(false),
                              isSecondary: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildButton(
                              text: _isSubmitting ? 'Submitting...' : 'Rate Now',
                              onPressed: _selectedStars >= 4 
                                  ? _requestReview 
                                  : null,
                              isLoading: _isSubmitting,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Skip button
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'Maybe Later',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback? onPressed,
    bool isSecondary = false,
    bool isLoading = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isSecondary 
            ? null 
            : LinearGradient(
                colors: onPressed != null 
                    ? [AppColors.primary, AppColors.primaryLight]
                    : [Colors.grey.shade300, Colors.grey.shade400],
              ),
        color: isSecondary ? Colors.grey.shade100 : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onPressed != null && !isSecondary
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isSecondary 
                          ? AppColors.textSecondary 
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// Helper function to show the styled review dialog
Future<bool?> showStyledReviewDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const StyledReviewDialog(),
  );
} 