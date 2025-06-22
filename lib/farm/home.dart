import 'package:flutter/material.dart';

class HomeLandingPage extends StatefulWidget {
  const HomeLandingPage({super.key});

  @override
  State<HomeLandingPage> createState() => _HomeLandingPageState();
}

class _HomeLandingPageState extends State<HomeLandingPage> {
  final List<FAQItem> faqs = [
    FAQItem(
      question: "What does this app offer?",
      answer:
          "Our farm management app provides comprehensive tools for livestock tracking, crop monitoring, weather integration, and market analysis - all in one platform.",
    ),
    FAQItem(
      question: "Who can use this app?",
      answer:
          "Designed for farmers, agricultural cooperatives, and agribusiness managers of all scales - from small family farms to large commercial operations.",
    ),
    FAQItem(
      question: "Is there a free trial?",
      answer:
          "Yes! We offer a 30-day free trial with full access to all basic features. No credit card required.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: Container(
                  height: constraints.maxHeight * 0.6, // Reduced height
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.green.shade50, Colors.green.shade100],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50, // Adjusted position
                        top: 20,
                        child: Opacity(
                          opacity: 0.3,
                          child: Image.asset(
                            'assets/scafold/sprout.png',
                            width: 300,
                            height: 300,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth * 0.08,
                          vertical: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'FarmSmart',
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 48 : 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Modern farm management at your fingertips',
                              style: TextStyle(
                                fontSize: constraints.maxWidth > 600 ? 22 : 18,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 30),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/farm/signup',
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    backgroundColor: Colors.green.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Get Started',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/farm/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: Colors.green.shade600,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Login',
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Features Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: 24,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 900
                        ? 3
                        : constraints.maxWidth > 600
                        ? 2
                        : 1,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: constraints.maxWidth > 600 ? 0.9 : 1.4,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final features = [
                      FeatureItem(
                        icon: Icons.analytics,
                        title: "Real-time Analytics",
                        description:
                            "Track livestock health and crop growth metrics",
                      ),
                      FeatureItem(
                        icon: Icons.cloud,
                        title: "Weather Integration",
                        description:
                            "Get hyper-local weather forecasts for your fields",
                      ),
                      FeatureItem(
                        icon: Icons.shopping_cart,
                        title: "Market Prices",
                        description: "Access real-time commodity pricing data",
                      ),
                    ];
                    return FeatureCard(feature: features[index]);
                  }, childCount: 3),
                ),
              ),

              // FAQ Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Frequently Asked Questions",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...faqs.map((faq) => FAQDropdown(faq: faq)).toList(),
                    ],
                  ),
                ),
              ),

              // CTA Section - Moved up and made more prominent
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    24,
                    0,
                    24,
                    40,
                  ), // Reduced bottom margin
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Ready to transform your farming operations?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/farm/signup');
                          },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Create Free Account',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Custom Widgets with improved styling
class FeatureCard extends StatelessWidget {
  final FeatureItem feature;

  const FeatureCard({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature.icon, size: 30, color: Colors.green.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              feature.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              feature.description,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class FAQDropdown extends StatefulWidget {
  final FAQItem faq;

  const FAQDropdown({super.key, required this.faq});

  @override
  State<FAQDropdown> createState() => _FAQDropdownState();
}

class _FAQDropdownState extends State<FAQDropdown> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100, width: 1.5),
      ),
      child: ExpansionTile(
        title: Text(
          widget.faq.question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.faq.answer,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        trailing: Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Colors.green.shade600,
        ),
      ),
    );
  }
}

// Data Models remain the same
class FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
