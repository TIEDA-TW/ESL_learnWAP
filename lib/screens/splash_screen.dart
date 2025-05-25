import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:english_learning_app/screens/login_form_screen.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // 新增動物角色位置追蹤
  List<Map<String, dynamic>> animalPositions = [];
  Timer? _animalTimer;
  
  // 新增粒子效果
  List<Particle> particles = [];
  Timer? _particleTimer;
  late AnimationController _logoController;
  late AnimationController _bounceController;
  late AnimationController _starController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _rotationAnimation;
  
  // 動畫元素控制器
  late List<AnimationController> _bubbleControllers;
  late List<Animation<double>> _bubbleAnimations;
  
  // 彩虹顏色
  final List<Color> rainbowColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
  ];
  
  // 可愛的動物表情符號
  final List<String> animalEmojis = ['🐰', '🐻', '🦊', '🦁', '🐼', '🦄', '🐸', '🐨'];
  
  // 學習相關圖標
  final List<String> learningEmojis = ['📚', '✏️', '🎯', '🌟', '🎨', '🎵', '💡', '🏆'];

  @override
  void initState() {
    super.initState();

    // Logo 主動畫控制器
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // 彈跳動畫控制器
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // 星星閃爍動畫控制器
    _starController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // Logo 縮放動畫 - 更誇張的彈性效果
    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    
    // Logo 旋轉動畫
    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // 文字淡入動畫
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    
    // 彈跳動畫
    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -20,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));
    
    // 初始化泡泡動畫
    _initBubbleAnimations();
    
    // 開始動畫序列
    _startAnimationSequence();
    
    // 初始化動物角色
    _startAnimalAnimation();
    
    // 初始化粒子效果
    _startParticleEffect();
    
    // 設置計時器，6秒後導航到登入表單頁面
    Timer(const Duration(seconds: 6), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => LoginFormScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }
  
  void _initBubbleAnimations() {
    _bubbleControllers = List.generate(6, (index) => 
      AnimationController(
        duration: Duration(seconds: 3 + index),
        vsync: this,
      )..repeat(reverse: true)
    );
    
    _bubbleAnimations = _bubbleControllers.map((controller) => 
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut)
      )
    ).toList();
  }
  
  void _startAnimationSequence() async {
    // 開始 Logo 動畫
    _logoController.forward();
    
    // 延遲後開始彈跳動畫
    await Future.delayed(const Duration(milliseconds: 1500));
    _bounceController.repeat(reverse: true);
    
    // 開始星星閃爍
    _starController.repeat(reverse: true);
    
    // 震動反饋
    if (mounted) {
      HapticFeedback.lightImpact();
    }
  }
  
  void _startAnimalAnimation() {
    _animalTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted && animalPositions.length < 6) {
        setState(() {
          animalPositions.add({
            'emoji': animalEmojis[math.Random().nextInt(animalEmojis.length)],
            'position': Offset(
              math.Random().nextDouble() * MediaQuery.of(context).size.width,
              -50
            ),
            'speed': 2.0 + math.Random().nextDouble() * 3.0,
            'wiggle': math.Random().nextDouble() * 0.5,
          });
        });
      }
    });
  }
  
  void _startParticleEffect() {
    _particleTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && particles.length < 30) {
        setState(() {
          particles.add(Particle(
            position: Offset(
              MediaQuery.of(context).size.width / 2 + (math.Random().nextDouble() - 0.5) * 200,
              MediaQuery.of(context).size.height / 2
            ),
            velocity: Offset(
              (math.Random().nextDouble() - 0.5) * 5,
              -math.Random().nextDouble() * 10 - 5
            ),
            color: rainbowColors[math.Random().nextInt(rainbowColors.length)],
            size: math.Random().nextDouble() * 6 + 2,
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bounceController.dispose();
    _starController.dispose();
    _animalTimer?.cancel();
    _particleTimer?.cancel();
    for (var controller in _bubbleControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _updateAnimals() {
    setState(() {
      animalPositions = animalPositions.map((animal) {
        final newY = animal['position'].dy + animal['speed'];
        final newX = animal['position'].dx + math.sin(newY * 0.02) * animal['wiggle'] * 50;
        return {
          ...animal,
          'position': Offset(newX, newY),
        };
      }).where((animal) => animal['position'].dy < MediaQuery.of(context).size.height + 50).toList();
    });
  }
  
  void _updateParticles() {
    setState(() {
      particles = particles.map((particle) {
        particle.position = Offset(
          particle.position.dx + particle.velocity.dx,
          particle.position.dy + particle.velocity.dy
        );
        particle.velocity = Offset(
          particle.velocity.dx,
          particle.velocity.dy + 0.3 // gravity
        );
        particle.life -= 0.02;
        return particle;
      }).where((particle) => particle.life > 0).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 更新動畫
    _updateAnimals();
    _updateParticles();
    
    return Scaffold(
      body: Stack(
        children: [
          // 動態背景漸層 - 更豐富的顏色
          AnimatedContainer(
            duration: const Duration(seconds: 3),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF87CEEB).withOpacity(0.9), // 天空藍
                  Color(0xFFFFB6C1), // 淺粉紅
                  Color(0xFF98FB98).withOpacity(0.9), // 薄荷綠
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // 動態泡泡背景
          ..._buildBubbles(),
          
          // 飄落的動物角色
          ...animalPositions.map((animal) => Positioned(
            left: animal['position'].dx,
            top: animal['position'].dy,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  // 點擊時彈出小愛心
                  particles.addAll(List.generate(5, (i) => Particle(
                    position: animal['position'],
                    velocity: Offset(
                      (math.Random().nextDouble() - 0.5) * 10,
                      -math.Random().nextDouble() * 5 - 5
                    ),
                    color: Colors.pink,
                    size: 8,
                    isHeart: true,
                  )));
                  animalPositions.remove(animal);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  animal['emoji'],
                  style: const TextStyle(fontSize: 30),
                ),
              ),
            ),
          )).toList(),
          
          // 粒子效果
          ...particles.map((particle) => Positioned(
            left: particle.position.dx,
            top: particle.position.dy,
            child: Opacity(
              opacity: particle.life,
              child: particle.isHeart
                  ? Icon(
                      Icons.favorite,
                      color: particle.color,
                      size: particle.size,
                    )
                  : Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                        color: particle.color,
                        shape: BoxShape.circle,
                      ),
                    ),
            ),
          )).toList(),
          
          // 主要內容
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo 容器
                AnimatedBuilder(
                  animation: Listenable.merge([_bounceAnimation, _rotationAnimation]),
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..translate(0.0, _bounceAnimation.value)
                        ..rotateZ(_rotationAnimation.value),
                      child: child,
                    );
                  },
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 旋轉的彩虹圓環背景
                          AnimatedBuilder(
                          animation: _logoController,
                          builder: (context, child) {
                            return Transform.rotate(
                            angle: _logoController.value * 2 * math.pi,
                            child: Container(
                            width: 170,
                            height: 170,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                    gradient: SweepGradient(
                            colors: [...rainbowColors, rainbowColors.first],
                            stops: List.generate(8, (index) => index / 7),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                          // 白色內圓
                          Container(
                            width: 150,
                            height: 150,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          // Logo 圖片
                          Image.asset(
                            'assets/images/ESL Logo.png',
                            width: 120,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // 標題文字，帶有彩虹色動畫
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: rainbowColors,
                    ).createShader(bounds),
                    child: const Text(
                      '歡迎來到魔法英語世界！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Noto Sans TC',
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // 副標題
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    '台灣兒童美語協會\nESL美語學習系統',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontFamily: 'Noto Sans TC',
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black26,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 50),
                
                // 可愛的載入動畫 - 學習圖標
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return AnimatedBuilder(
                      animation: _starController,
                      builder: (context, child) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              math.sin(_starController.value * math.pi * 2 + index) * 10,
                            ),
                            child: Transform.scale(
                              scale: 0.8 + (_starController.value * 0.3),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: rainbowColors[index % rainbowColors.length]
                                          .withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  learningEmojis[index],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
                
                const SizedBox(height: 20),
                
                // 載入文字
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    '準備開始學習囉！',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 建立動態泡泡
  List<Widget> _buildBubbles() {
    return List.generate(6, (index) {
      final size = 40.0 + (index * 20);
      final left = (index * 60.0) % 300;
      
      return AnimatedBuilder(
        animation: _bubbleAnimations[index],
        builder: (context, child) {
          return Positioned(
            left: left,
            bottom: -50 + (_bubbleAnimations[index].value * MediaQuery.of(context).size.height * 1.2),
            child: Opacity(
              opacity: 0.3,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rainbowColors[index % rainbowColors.length],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

// 粒子類別
class Particle {
  Offset position;
  Offset velocity;
  Color color;
  double size;
  double life;
  bool isHeart;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.size,
    this.life = 1.0,
    this.isHeart = false,
  });
} 