
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color primary = Color(0xFFA33900);
  static const Color secondary = Color(0xFF006C4A);
  static const Color background = Color(0xFFFAF8FF);

Future<void> _nextPage() async {
  if (_currentPage < 2) {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  } else {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    context.go('/login');
  }
}
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              currentPage: _currentPage,
              onSkip: _skip,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _FirstScreen(
                    onContinue: _nextPage,
                    onSignIn: () => context.go('/login'),
                  ),
                  _SecondScreen(
                    onBack: _previousPage,
                    onNext: _nextPage,
                  ),
                  _ThirdScreen(
                    onGetStarted: _nextPage,
                    onTerms: () => _showMessage('Terms & Conditions'),
                    onPrivacy: () => _showMessage('Privacy Policy'),
                    onPartnerLogin: () =>
                        _showMessage('Partner Login selected'),
                  ),
                ],
              ),
            ),
            _PageIndicator(currentPage: _currentPage),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// COMMON HEADER
// ------------------------------------------------------------

class _Header extends StatelessWidget {
  final int currentPage;
  final VoidCallback onSkip;

  const _Header({
    required this.currentPage,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Row(
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Color(0xFFA33900),
            size: 27,
          ),
          const SizedBox(width: 9),
          const Text(
            'KOVAI BITES',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: Color(0xFF30231D),
            ),
          ),
          const Spacer(),
          if (currentPage == 2)
            const Text(
              'STEP 3 OF 3',
              style: TextStyle(
                color: Color(0xFF006C4A),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            )
          else
            TextButton(
              onPressed: onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SCREEN 1 - TASTE OF COIMBATORE
// ------------------------------------------------------------

class _FirstScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onSignIn;

  const _FirstScreen({
    required this.onContinue,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return _ResponsivePage(
      imageUrl:
          'https://images.unsplash.com/photo-1547592180-85f173990554?w=1200',
      imageLabel: 'Authentic South Indian Food',
      badge: 'COIMBATORE FOOD EXPERIENCE',
      title: 'Taste of Coimbatore Delivered Hot & Fresh',
      description:
          'Discover the authentic flavours of Kovai. Your favourite local kitchens, delivered fresh to your doorstep.',
      imageTag: '50+ Iconic Kitchens',
      imageSubTag: 'Authentic local flavours',
      features: const [
        _FeatureData(
          icon: Icons.restaurant,
          title: '50+ Iconic Kitchens',
          subtitle: 'Explore your favourite local restaurants',
        ),
        _FeatureData(
          icon: Icons.delivery_dining,
          title: 'Hyperlocal 25m Express',
          subtitle: 'Fresh food delivered faster',
        ),
      ],
      buttonText: 'Continue to Tour',
      onButtonPressed: onContinue,
      footer: GestureDetector(
                onTap: onSignIn,
                child: Text.rich(
                    const TextSpan(
                    text: 'Already have an account? ',
                    children: [
                        TextSpan(
                        text: 'Sign In',
                        style: TextStyle(
                            color: Color(0xFFA33900),
                            fontWeight: FontWeight.bold,
                        ),
                        ),
                    ],
                    ),
                    textAlign: TextAlign.center,
                ),
                ),
    );
  }
}

// ------------------------------------------------------------
// SCREEN 2 - LIVE RADAR & DELIVERY
// ------------------------------------------------------------

class _SecondScreen extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _SecondScreen({
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _ResponsivePage(
      imageUrl:
          'https://images.unsplash.com/photo-1526367790999-0150786686a2?w=1200',
      imageLabel: 'Delivery Rider',
      badge: 'KOVAI RADAR • LIVE 60Hz',
      title: 'Lightning Hyperlocal Delivery & Live Radar',
      description:
          'Track your order in real time. Smart routing connects local kitchens and delivery partners for a faster experience.',
      imageTag: 'LIVE TRACKING',
      imageSubTag: 'Courier 4B • ETA 19:45',
      features: const [
        _FeatureData(
          icon: Icons.route,
          title: '3.8 min Pickup Latency',
          subtitle: 'Optimised pickup and delivery routes',
        ),
        _FeatureData(
          icon: Icons.verified,
          title: '98.4% On-time SLA',
          subtitle: 'Reliable hyperlocal delivery',
        ),
        _FeatureData(
          icon: Icons.sensors,
          title: 'Smart IoT Telematics',
          subtitle: 'Stay updated throughout your order',
        ),
      ],
      buttonText: 'Next: Merchant Network',
      onButtonPressed: onNext,
      secondaryButtonText: 'Previous',
      onSecondaryPressed: onBack,
      imageExtra: const _NavigationCard(),
    );
  }
}

// ------------------------------------------------------------
// SCREEN 3 - COMMUNITY FIRST
// ------------------------------------------------------------

class _ThirdScreen extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onTerms;
  final VoidCallback onPrivacy;
  final VoidCallback onPartnerLogin;

  const _ThirdScreen({
    required this.onGetStarted,
    required this.onTerms,
    required this.onPrivacy,
    required this.onPartnerLogin,
  });

  @override
  Widget build(BuildContext context) {
    return _ResponsivePage(
      imageUrl:
          'https://images.unsplash.com/photo-1577219491135-ce391730fb2c?w=1200',
      imageLabel: 'Chef Preparing Food',
      badge: 'FAIR MERCHANT & RIDER PARTNERSHIP',
      title: 'Community-First Delivery',
      description:
          'A better food delivery experience built around local businesses, delivery partners and the people of Coimbatore.',
      imageTag: '21 MINS AVERAGE TRANSIT',
      imageSubTag: 'RS Puram to Gandhipuram',
      features: const [
        _FeatureData(
          icon: Icons.payments_outlined,
          title: 'Zero Surge Hidden Fees',
          subtitle: 'Transparent pricing for every order',
        ),
        _FeatureData(
          icon: Icons.soup_kitchen_outlined,
          title: 'Direct Kitchen Prep & Live KOT',
          subtitle: 'Fresh preparation updates',
        ),
        _FeatureData(
          icon: Icons.security,
          title: 'Instant 2FA & UPI 1-Tap Checkout',
          subtitle: 'Simple and secure checkout experience',
        ),
      ],
      buttonText: 'Get Started with Kovai Bites',
      onButtonPressed: onGetStarted,
      imageExtra: const _SlaCard(),
      footer: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          _FooterLink(text: 'Terms', onTap: onTerms),
          _FooterLink(text: 'Privacy Policy', onTap: onPrivacy),
          _FooterLink(text: 'Partner / Admin Login', onTap: onPartnerLogin),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// COMMON RESPONSIVE PAGE
// ------------------------------------------------------------

class _ResponsivePage extends StatelessWidget {
  final String imageUrl;
  final String imageLabel;
  final String badge;
  final String title;
  final String description;
  final String imageTag;
  final String imageSubTag;
  final List<_FeatureData> features;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Widget? imageExtra;
  final Widget? footer;

  const _ResponsivePage({
    required this.imageUrl,
    required this.imageLabel,
    required this.badge,
    required this.title,
    required this.description,
    required this.imageTag,
    required this.imageSubTag,
    required this.features,
    required this.buttonText,
    required this.onButtonPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.imageExtra,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        final image = _HeroImage(
          imageUrl: imageUrl,
          imageLabel: imageLabel,
          imageTag: imageTag,
          imageSubTag: imageSubTag,
          extra: imageExtra,
        );

        final content = _PageContent(
          badge: badge,
          title: title,
          description: description,
          features: features,
          buttonText: buttonText,
          onButtonPressed: onButtonPressed,
          secondaryButtonText: secondaryButtonText,
          onSecondaryPressed: onSecondaryPressed,
          footer: footer,
        );

        if (isDesktop) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1150),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 20,
                ),
                child: Row(
                  children: [
                    Expanded(child: image),
                    const SizedBox(width: 55),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 25),
          child: Column(
            children: [
              SizedBox(
                height: constraints.maxHeight * 0.37,
                child: image,
              ),
              const SizedBox(height: 28),
              content,
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// COMMON HERO IMAGE
// ------------------------------------------------------------

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final String imageLabel;
  final String imageTag;
  final String imageSubTag;
  final Widget? extra;

  const _HeroImage({
    required this.imageUrl,
    required this.imageLabel,
    required this.imageTag,
    required this.imageSubTag,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFFFFE9D9),
                child: const Icon(
                  Icons.restaurant,
                  size: 90,
                  color: Color(0xFFA33900),
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (extra != null) extra!,
                const SizedBox(height: 12),
                Text(
                  imageTag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  imageSubTag,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
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

// ------------------------------------------------------------
// COMMON CONTENT
// ------------------------------------------------------------

class _PageContent extends StatelessWidget {
  final String badge;
  final String title;
  final String description;
  final List<_FeatureData> features;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String? secondaryButtonText;
  final VoidCallback? onSecondaryPressed;
  final Widget? footer;

  const _PageContent({
    required this.badge,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onButtonPressed,
    this.secondaryButtonText,
    this.onSecondaryPressed,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9D9),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            badge,
            style: const TextStyle(
              color: Color(0xFFA33900),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 17),
        Text(
          title,
          style: const TextStyle(
            fontSize: 31,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: Color(0xFF30231D),
          ),
        ),
        const SizedBox(height: 13),
        Text(
          description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 22),
        ...features.map((feature) => _FeatureTile(data: feature)),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: onButtonPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA33900),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        if (secondaryButtonText != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton(
              onPressed: onSecondaryPressed,
              child: Text(secondaryButtonText!),
            ),
          ),
        ],
        if (footer != null) ...[
          const SizedBox(height: 18),
          Center(child: footer!),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------
// COMMON FEATURE TILE
// ------------------------------------------------------------

class _FeatureData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _FeatureTile extends StatelessWidget {
  final _FeatureData data;

  const _FeatureTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9D9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              data.icon,
              color: const Color(0xFFA33900),
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF30231D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
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

// ------------------------------------------------------------
// SCREEN 2 - NAVIGATION CARD
// ------------------------------------------------------------

class _NavigationCard extends StatelessWidget {
  const _NavigationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          Icon(Icons.turn_left, color: Color(0xFFA33900), size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '140 m • Turn left',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '3.2 km remaining',
                  style: TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF006C4A),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SCREEN 3 - SLA CARD
// ------------------------------------------------------------

class _SlaCard extends StatelessWidget {
  const _SlaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Color(0xFF006C4A)),
          SizedBox(width: 8),
          Text(
            '99.4% SLA',
            style: TextStyle(
              color: Color(0xFF006C4A),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// COMMON PAGE INDICATOR
// ------------------------------------------------------------

class _PageIndicator extends StatelessWidget {
  final int currentPage;

  const _PageIndicator({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          final isActive = currentPage == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 25 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFA33900)
                  : const Color(0xFFD8C8BE),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }
}

// ------------------------------------------------------------
// COMMON FOOTER LINK
// ------------------------------------------------------------

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFA33900),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
