import 'package:flutter/material.dart';

class JumpingLoader extends StatefulWidget {
  const JumpingLoader({super.key});

  @override
  State<JumpingLoader> createState() => _JumpingLoaderState();
}

class _JumpingLoaderState extends State<JumpingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _jumpAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _shadowScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat();

    // Jump (translateY)
    _jumpAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -18.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: -36.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -36.0, end: -18.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -18.0, end: 0.0), weight: 25),
    ]).animate(_controller);

    // Rotation (0 → 90deg)
    _rotateAnimation = Tween<double>(begin: 0, end: 90).animate(_controller);

    // Shadow scaling
    _shadowScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 14, 14, 14), // White background
      child: Center(
        child: SizedBox(
          width: 60,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Shadow
              AnimatedBuilder(
                animation: _shadowScale,
                builder: (_, child) {
                  return Transform.scale(
                    scaleX: _shadowScale.value,
                    scaleY: 1,
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      margin: const EdgeInsets.only(top: 60),
                    ),
                  );
                },
              ),
              // Jumping cube
              AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  return Transform.translate(
                    offset: Offset(0, _jumpAnimation.value),
                    child: Transform.rotate(
                      angle: _rotateAnimation.value * 3.1416 / 180,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB), // Blue cube
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color.fromARGB(255, 192, 192, 192).withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
