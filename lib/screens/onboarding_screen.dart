// lib/pages/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/pages/auth_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    const OnboardingData(
      backgroundColor:  Color(0xFF4F46E5), // Blue-purple
      title: "Fast, Fluid and Secure",
      subtitle: "Enjoy the best of the world in the\npalm of your hands.",
      imageAsset: "assets/images/save_time.png", // Clock and person illustration
      buttonText: "Next",
      isLastPage: false,
    ),
    const OnboardingData(
      backgroundColor:  Color(0xFF10B981), // Green
      title: "Plan efficiently",
      subtitle: "plan your month with lots of events,\nand avoid hectic days",
      imageAsset: "assets/images/scheduling.png", // Calendar and person illustration
      buttonText: "Next",
      isLastPage: false,
    ),
    const OnboardingData(
      backgroundColor:  Color(0xFFF59E0B), // Orange
      title: "Say goodbye to manual fill up !",
      subtitle: "say goodbye to filling up forms live at site.",
      imageAsset: "assets/images/filling_forms.png", // People at desk illustration
      buttonText: "Next",
      isLastPage: false,
    ),
    const OnboardingData(
      backgroundColor:  Color(0xFF8B5CF6), // Purple
      title: "Relax",
      subtitle: "now all you have to do is sit back and\nenjoy your day!",
      imageAsset: "assets/images/relaxation.png", // Person relaxing illustration
      buttonText: "Finish",
      isLastPage: true,
    ),
  ];

  Future<void> _completeOnboarding() async {
    // Mark onboarding as complete
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    
    // Navigate to auth page
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(data: _pages[index]);
            },
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // Handle skip action
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == _currentPage 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Handle finish action - mark onboarding as complete
                      _completeOnboarding();
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _pages[_currentPage].buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!_pages[_currentPage].isLastPage) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
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

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.data});

  final OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            data.backgroundColor,
            data.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Image Asset
              SizedBox(
                width: double.infinity,
                height: 300,
                child: Center(
                  child: Image.asset(
                    data.imageAsset,
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // Title
              Text(
                data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Subtitle
              Text(
                data.subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final Color backgroundColor;
  final String title;
  final String subtitle;
  final String imageAsset;
  final String buttonText;
  final bool isLastPage;

  const OnboardingData({
    required this.backgroundColor,
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.buttonText,
    required this.isLastPage,
  });
}