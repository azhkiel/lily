import 'package:flutter/material.dart';
import 'package:mentaly/theme/app_theme.dart';
import 'package:mentaly/screens/auth/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

// Model data halaman onboarding
class OnboardingPageData {
  final String title;
  final String description;
  final String imageAsset;

  OnboardingPageData({
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data onboarding pakai model class agar lebih rapi
  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Selamat Datang di Mentaly',
      description:
          'Tempat di mana pikiranmu mendapat ketenangan dan dukungan yang Anda butuhkan.',
      imageAsset: 'assets/onboarding1.png',
    ),
    OnboardingPageData(
      title: 'Kamu Tidak Sendiri',
      description:
          'Berbagi, belajar, dan tumbuh bersama. Kami ada di sini untukmu, setiap langkah.',
      imageAsset: 'assets/onboarding2.png',
    ),
    OnboardingPageData(
      title: 'Mari Mulai Perjalananmu',
      description:
          'Temukan ketenangan, bangun kekuatan, dan jadilah versi terbaik dari dirimu.',
      imageAsset: 'assets/onboarding3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goToLogin();
    }
  }

  void _onSkip() {
    _goToLogin();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _currentPage == index ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppColors.primary : AppColors.gray,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.secondaryLightest,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Image.asset(
                              page.imageAsset,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: textTheme.headlineLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.grayDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _buildPageIndicator(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _onSkip,
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: _onNextPage,
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
