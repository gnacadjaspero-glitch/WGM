import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../theme.dart';
import 'gerant_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _bgGlow;
  
  final List<Particle> _particles = List.generate(25, (index) => Particle());

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.5, curve: Curves.easeIn)),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.6, curve: Curves.elasticOut)),
    );

    _bgGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 1.0, curve: Curves.easeInOut)),
    );

    _mainController.forward();

    Timer(const Duration(milliseconds: 5500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const GerantScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          // 1. Particules de fond (Formes Gaming)
          ..._particles.map((p) => ParticleWidget(particle: p)),

          // 2. Lueur de fond (Harmonisée avec le logo : Cyan -> Violet -> Rose)
          AnimatedBuilder(
            animation: _bgGlow,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.2), // Décentré vers le haut droite pour la lueur rose
                    radius: 1.8,
                    colors: [
                      const Color(0xFFFF4D94).withValues(alpha: 0.08 * _bgGlow.value), // Rose (Côté main)
                      const Color(0xFF9D50BB).withValues(alpha: 0.10 * _bgGlow.value), // Violet (Centre)
                      AppColors.accent.withValues(alpha: 0.08 * _bgGlow.value),       // Cyan (Côté gauche)
                      AppColors.bgBase,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),

          const ScanlineWidget(),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // LOGO
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                      child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.03),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.2 * _pulseController.value),
                                blurRadius: 40 * _pulseController.value,
                                spreadRadius: 2,
                                offset: const Offset(-10, 0),
                              ),
                              BoxShadow(
                                color: const Color(0xFFFF4D94).withValues(alpha: 0.2 * _pulseController.value),
                                blurRadius: 40 * _pulseController.value,
                                spreadRadius: 2,
                                offset: const Offset(10, 0),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0), // Marge interne pour que le logo ne touche pas les bords du cercle
                              child: Transform.scale(
                                scale: 1.0 + (0.03 * _pulseController.value),
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Image.asset(
                        'assets/images/Logo_Final.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // TEXTE
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Text(
                          'WINNER GAME MANAGER',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(
                                color: AppColors.accent.withValues(alpha: 0.8 * _pulseController.value),
                                blurRadius: 20 * _pulseController.value,
                                offset: const Offset(-2, 0),
                              ),
                              Shadow(
                                color: const Color(0xFFFF4D94).withValues(alpha: 0.8 * _pulseController.value),
                                blurRadius: 20 * _pulseController.value,
                                offset: const Offset(2, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'MANAGEMENT • PROFIT • GAMING',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 6,
                            color: AppColors.accent.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 70),

                // Loader
                SizedBox(
                  width: 220,
                  height: 3,
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _mainController,
                        builder: (context, child) {
                          return FractionallySizedBox(
                            widthFactor: _mainController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    Color(0xFF9D50BB), // Violet
                                    Color(0xFFFF4D94), // Rose
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ParticleType { triangle, circle, square, cross, dollar }

class Particle {
  late double x, y, size, speed, rotation;
  late double opacity;
  late ParticleType type;
  late Color color;

  Particle() {
    reset();
  }

  void reset() {
    x = math.Random().nextDouble();
    y = math.Random().nextDouble() * 1.2;
    size = math.Random().nextDouble() * 12 + 5;
    speed = math.Random().nextDouble() * 0.0012 + 0.0004;
    opacity = math.Random().nextDouble() * 0.4 + 0.1;
    rotation = math.Random().nextDouble() * math.pi * 2;
    type = ParticleType.values[math.Random().nextInt(ParticleType.values.length)];
    
    // Couleurs harmonisées avec le logo
    final colors = [
      AppColors.accent,         // Cyan
      const Color(0xFF9D50BB),  // Violet
      const Color(0xFFFF4D94),  // Rose
    ];
    color = colors[math.Random().nextInt(colors.length)];
  }
}

class ParticleWidget extends StatefulWidget {
  final Particle particle;
  const ParticleWidget({super.key, required this.particle});

  @override
  State<ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<ParticleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        widget.particle.y -= widget.particle.speed;
        widget.particle.rotation += 0.01;
        if (widget.particle.y < -0.1) widget.particle.y = 1.1;
        
        return Positioned(
          left: widget.particle.x * MediaQuery.of(context).size.width,
          top: widget.particle.y * MediaQuery.of(context).size.height,
          child: Transform.rotate(
            angle: widget.particle.rotation,
            child: Opacity(
              opacity: widget.particle.opacity,
              child: _buildShape(widget.particle.type, widget.particle.size, widget.particle.color),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShape(ParticleType type, double size, Color color) {
    switch (type) {
      case ParticleType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.2),
            shape: BoxShape.circle,
          ),
        );
      case ParticleType.square:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.2),
          ),
        );
      case ParticleType.triangle:
        return CustomPaint(
          size: Size(size, size),
          painter: TrianglePainter(color: color),
        );
      case ParticleType.cross:
        return Icon(Icons.add, color: color, size: size);
      case ParticleType.dollar:
        return Text(
          '\$',
          style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );
    }
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ScanlineWidget extends StatelessWidget {
  const ScanlineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: List.generate(100, (index) => 
              index % 2 == 0 ? Colors.black.withValues(alpha: 0.03) : Colors.transparent
            ),
          ),
        ),
      ),
    );
  }
}
