import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leap Away',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Leap Away',
              style: TextStyle(
                fontSize: 50.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Tap to jump right, avoid obstacles, and collect coins!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                textStyle: const TextStyle(fontSize: 24),
              ),
              child: const Text('Start Game'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _playerX = 0;
  double _playerY = 0;
  double _playerVelocityY = 0;
  final double _gravity = 0.5;
  final double _jumpStrength = -10.0;
  int _score = 0;
  bool _isGameOver = false;

  final List<Offset> _platforms = [];
  final List<Offset> _coins = [];
  final Random _random = Random();
  final double _platformWidth = 80.0;
  final double _platformHeight = 20.0;
  double _cameraX = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_gameLoop);

    _resetGame();
  }

  void _resetGame() {
    setState(() {
      _playerX = 0;
      _playerY = 0;
      _playerVelocityY = 0;
      _score = 0;
      _isGameOver = false;
      _cameraX = 0.0;
      _platforms.clear();
      _coins.clear();

      // Create initial platforms
      for (int i = 0; i < 10; i++) {
        _platforms.add(Offset(i * 120.0, _random.nextDouble() * 200 + 100));
        if (i > 1 && _random.nextBool()) {
          _coins.add(_platforms.last + Offset(_platformWidth / 2, -30));
        }
      }
    });
    _controller.repeat();
  }

  void _gameLoop() {
    if (_isGameOver) {
      _controller.stop();
      return;
    }

    setState(() {
      // Player physics
      _playerVelocityY += _gravity;
      _playerY += _playerVelocityY;
      _playerX += 2.0; // Player constantly moves right

      // Camera follows player
      _cameraX = _playerX - MediaQuery.of(context).size.width / 4;

      // Check for landing on platforms
      bool onPlatform = false;
      for (var platform in _platforms) {
        if (_playerX + 20 > platform.dx &&
            _playerX < platform.dx + _platformWidth &&
            _playerY + 20 > platform.dy &&
            _playerY + 20 < platform.dy + _platformHeight &&
            _playerVelocityY > 0) {
          _playerVelocityY = 0;
          _playerY = platform.dy - 20;
          onPlatform = true;
        }
      }

      // Check for falling off screen
      if (_playerY > MediaQuery.of(context).size.height) {
        _isGameOver = true;
      }
      
      // Collect coins
      _coins.removeWhere((coin) {
        if ((coin.dx - _playerX).abs() < 30 && (coin.dy - _playerY).abs() < 30) {
          _score++;
          return true;
        }
        return false;
      });

      // Generate new platforms and coins
      if (_platforms.last.dx < _playerX + MediaQuery.of(context).size.width) {
        _platforms.add(Offset(_platforms.last.dx + 120 + _random.nextDouble() * 50,
            _random.nextDouble() * 200 + 100));
        if (_random.nextBool()) {
          _coins.add(_platforms.last + Offset(_platformWidth / 2, -30));
        }
      }

      // Remove old platforms
      _platforms.removeWhere((p) => p.dx < _cameraX - _platformWidth);
      _coins.removeWhere((c) => c.dx < _cameraX - 20);
    });
  }

  void _jump() {
    if (_isGameOver) return;
    setState(() {
      _playerVelocityY = _jumpStrength;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: Stack(
          children: [
            // Background
            Container(color: Colors.lightBlue[100]),
            
            // Game elements
            ..._buildGameElements(),

            // Score display
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Game Over screen
            if (_isGameOver) _buildGameOver(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGameElements() {
    List<Widget> elements = [];

    // Platforms
    for (var platform in _platforms) {
      elements.add(
        Positioned(
          left: platform.dx - _cameraX,
          top: platform.dy,
          child: Container(
            width: _platformWidth,
            height: _platformHeight,
            color: Colors.green[700],
          ),
        ),
      );
    }
    
    // Coins
    for (var coin in _coins) {
      elements.add(
        Positioned(
          left: coin.dx - _cameraX,
          top: coin.dy,
          child: const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
        ),
      );
    }

    // Player
    elements.add(
      Positioned(
        left: _playerX - _cameraX,
        top: _playerY,
        child: Container(
          width: 20,
          height: 20,
          color: Colors.red,
        ),
      ),
    );

    return elements;
  }

  Widget _buildGameOver() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your Score: $_score',
              style: const TextStyle(
                fontSize: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: _resetGame,
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
