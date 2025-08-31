import 'package:flutter/material.dart';

class JumpingLoader extends StatefulWidget {
  const JumpingLoader({super.key});

  @override
  State<JumpingLoader> createState() => _JumpingLoaderState();
}

class _JumpingLoaderState extends State<JumpingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _opacityAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCircle(double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        double progress = (_controller.value + delay) % 1.0;
        return Transform.scale(
          scale: progress,
          child: Opacity(
            opacity: 1 - progress,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color.fromRGBO(0, 96, 250, 1), width: 16),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // <-- black background
      child: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _buildCircle(0.0), // first circle
              _buildCircle(0.5), // second circle delayed
            ],
          ),
        ),
      ),
    );
  }
}
