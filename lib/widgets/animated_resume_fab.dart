import 'package:flutter/material.dart';

class AnimatedResumeFab extends StatefulWidget {
  final VoidCallback onTap;
  final bool showLabel;
  final String label;
  final bool showNewBadge;
  const AnimatedResumeFab({
    required this.onTap,
    this.showLabel = true,
    this.label = 'Create Resume',
    this.showNewBadge = true,
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedResumeFab> createState() => _AnimatedResumeFabState();
}

class _AnimatedResumeFabState extends State<AnimatedResumeFab> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Stack(
              children: [
                // Main circular button with glow effect
                AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.4),
                            blurRadius: _glowAnim.value,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
                // NEW badge positioned on top
                if (widget.showNewBadge)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.showLabel)
          const SizedBox(height: 8),
        if (widget.showLabel)
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
              fontFamily: 'Poppins',
            ),
          ),
      ],
    );
  }
} 