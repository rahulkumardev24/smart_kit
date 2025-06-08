import 'package:flutter/material.dart';
import '../home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );

    // Create fade-in animation
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);

    // Start animation
    _controller.forward();

    // Navigate to home screen after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
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
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with subtle shadow
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Image.asset(
                  'assets/logo.png', // Your logo path
                  height: 100,
                  width: 100,
                ),
              ),
              SizedBox(height: 30),
              // App Name with gradient text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [Colors.blueAccent, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'ImagePDF Toolkit',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // This color will be replaced by gradient
                  ),
                ),
              ),
              SizedBox(height: 10),
              // Tagline
              Text(
                'Your Image Processing Companion',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 40),
              // Custom loading indicator
              Container(
                width: 100,
                height: 2,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}