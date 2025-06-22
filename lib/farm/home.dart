import 'package:flutter/material.dart';

class HomeLandingPage extends StatefulWidget {
  const HomeLandingPage({super.key});

  @override
  State<HomeLandingPage> createState() => _HomeLandingPageState();
}

class _HomeLandingPageState extends State<HomeLandingPage> {
  final List<FAQItem> faqs = [
    FAQItem(
      question: "What exactly does FarmSmart offer?",
      answer:
          "FarmSmart provides a comprehensive suite of agricultural management tools including:\n\n"
          "• Livestock health monitoring and tracking\n"
          "• Crop growth analytics and yield prediction\n"
          "• Soil condition monitoring\n"
          "• Weather forecasting tailored to your fields\n"
          "• Market price tracking for 50+ commodities\n"
          "• Equipment maintenance scheduling\n\n"
          "All data syncs across devices in real-time.",
    ),
    FAQItem(
      question: "What types of farms can benefit?",
      answer:
          "FarmSmart is designed for:\n\n"
          "• Small family farms (5+ acres)\n"
          "• Medium-sized commercial operations\n"
          "• Large-scale agribusinesses\n"
          "• Organic and specialty crop growers\n"
          "• Livestock producers (dairy, poultry, beef)\n"
          "• Agricultural cooperatives\n\n"
          "Our modular system adapts to your specific needs.",
    ),
    FAQItem(
      question: "How does the free trial work?",
      answer:
          "Our 30-day trial includes:\n\n"
          "✓ Full access to all core features\n"
          "✓ Support for up to 100 acres/livestock units\n"
          "✓ Basic weather forecasting\n"
          "✓ Market price alerts\n"
          "✓ 24/7 email support\n\n"
          "No credit card required. Cancel anytime.",
    ),
    FAQItem(
      question: "What devices are supported?",
      answer:
          "FarmSmart works on:\n\n"
          "• Android smartphones/tablets (6.0+)\n"
          "• iPhones/iPads (iOS 13+)\n"
          "• Web browsers (Chrome, Safari, Edge)\n"
          "• Desktop apps (Windows/macOS coming soon)\n\n"
          "All data syncs seamlessly across devices.",
    ),
    FAQItem(
      question: "How secure is my farm data?",
      answer:
          "We prioritize security with:\n\n"
          "• End-to-end encryption\n"
          "• Two-factor authentication\n"
          "• Regular security audits\n"
          "• GDPR compliance\n"
          "• Optional on-premise hosting for enterprises\n\n"
          "Your data never leaves your country/region.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight * 0.6,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 24 : 48,
                    vertical: 40,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.primaryContainer.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Image.asset(
                        'assets/scafold/sprout.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.agriculture, size: 80),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'FarmSmart Pro',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Precision agriculture management for modern farms',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withOpacity(
                            0.9,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 40),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? double.infinity : 200,
                            child: FilledButton(
                              onPressed: () => _navigateToSignup(context),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(' Quick Start'),
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? double.infinity : 200,
                            child: OutlinedButton(
                              onPressed: () => _navigateToLogin(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Existing User Login',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Features Section
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  vertical: 40,
                  horizontal: isSmallScreen ? 24 : 48,
                ),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isSmallScreen
                        ? 1
                        : constraints.maxWidth > 900
                        ? 3
                        : 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: isSmallScreen ? 1.4 : 0.9,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final features = [
                      FeatureItem(
                        icon: Icons.analytics,
                        title: "Advanced Analytics",
                        description:
                            "Real-time livestock health metrics and crop growth tracking with AI-powered insights",
                        details:
                            "• Track 20+ health indicators\n• Predictive yield modeling\n• Custom report generation",
                      ),
                      FeatureItem(
                        icon: Icons.cloud,
                        title: "Precision Weather",
                        description:
                            "Hyper-local forecasts tailored to your specific fields and crops",
                        details:
                            "• 72-hour forecasts\n• Frost/heat alerts\n• Rainfall predictions\n• Microclimate analysis",
                      ),
                      FeatureItem(
                        icon: Icons.shopping_cart,
                        title: "Market Intelligence",
                        description:
                            "Real-time commodity pricing and demand forecasting",
                        details:
                            "• 50+ crop/livestock markets\n• Price trend analysis\n• Optimal selling windows",
                      ),
                    ];
                    return FeatureCard(feature: features[index]);
                  }, childCount: 3),
                ),
              ),

              // Testimonials Section
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 48,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trusted by Farmers Worldwide",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTestimonialCard(
                              "Increased our yields by 22% in the first season",
                              "Raj Patel, Cotton Farm, India",
                            ),
                            const SizedBox(width: 16),
                            _buildTestimonialCard(
                              "Saved \$14,000 in feed costs through better tracking",
                              "Maria Gonzalez, Dairy Farm, Mexico",
                            ),
                            const SizedBox(width: 16),
                            _buildTestimonialCard(
                              "Weather alerts saved our strawberry crop twice",
                              "Thomas Müller, Berry Farm, Germany",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // FAQ Section
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 48,
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Frequently Asked Questions",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...faqs.map((faq) => FAQDropdown(faq: faq)).toList(),
                    ],
                  ),
                ),
              ),

              // CTA Section
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    isSmallScreen ? 24 : 48,
                    0,
                    isSmallScreen ? 24 : 48,
                    40,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Join 15,000+ Farms Using FarmSmart",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Start your 30-day free trial today. No credit card required.",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer.withOpacity(
                            0.9,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => _navigateToSignup(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 32,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Get Started Now'),
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

  Widget _buildTestimonialCard(String quote, String author) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 400),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$quote"',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSignup(BuildContext context) {
    try {
      Navigator.pushNamed(context, '/farm/signup');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error navigating to signup: $e')));
    }
  }

  void _navigateToLogin(BuildContext context) {
    try {
      Navigator.pushNamed(context, '/farm/login');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error navigating to login: $e')));
    }
  }
}

class FeatureCard extends StatelessWidget {
  final FeatureItem feature;

  const FeatureCard({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Feature details dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(feature.title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(feature.description),
                    const SizedBox(height: 16),
                    Text(feature.details),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.icon,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                feature.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                feature.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to learn more →',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ExpansionTile(
        title: Text(
          widget.faq.question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              widget.faq.answer,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        trailing: Icon(
          _isExpanded ? Icons.remove : Icons.add,
          color: theme.colorScheme.primary,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final String details;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.details,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
