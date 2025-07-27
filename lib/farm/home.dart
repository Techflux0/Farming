import 'package:flutter/material.dart';

class GoatFarmLandingPage extends StatefulWidget {
  const GoatFarmLandingPage({super.key});

  @override
  State<GoatFarmLandingPage> createState() => _GoatFarmLandingPageState();
}

class _GoatFarmLandingPageState extends State<GoatFarmLandingPage> {
  final List<FAQItem> faqs = [
    FAQItem(
      question: "How can Farm Pro help?",
      answer:
          "Health tracking, breeding management, milk analytics, and financial tools for goat farmers.",
    ),
    FAQItem(
      question: "Supported breeds?",
      answer: "Boer, Saanen, Alpine, Nubian, Angora, Pygmy and custom breeds.",
    ),
    FAQItem(
      question: "Free trial?",
      answer: "30-day trial for up to 50 goats with all core features.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.lightBlue],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.pets, size: 50, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Farm Pro',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Goat farming made simple',
                            style: TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildPillButton(
                            text: 'Sign Up',
                            onPressed: () => _navigateToSignup(context),
                            isFilled: true,
                            width: 150,
                          ),
                          const SizedBox(height: 12),
                          _buildPillButton(
                            text: 'Login',
                            onPressed: () => _navigateToLogin(context),
                            isFilled: false,
                            width: 150,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final features = [
                  FeatureItem(
                    icon: Icons.monitor_heart,
                    title: "Health",
                    description: "Track vitals & symptoms",
                    color: Colors.red[400]!,
                  ),
                  FeatureItem(
                    icon: Icons.family_restroom,
                    title: "Breeding",
                    description: "Heat cycles & pregnancies",
                    color: Colors.pink[400]!,
                  ),
                  FeatureItem(
                    icon: Icons.local_drink,
                    title: "Milk",
                    description: "Production analytics",
                    color: Colors.purple[400]!,
                  ),
                  FeatureItem(
                    icon: Icons.attach_money,
                    title: "Finance",
                    description: "Costs & profits",
                    color: Colors.lightBlue[400]!,
                  ),
                ];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.lightBlue[100]!, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildCompactFeatureCard(features[index]),
                );
              }, childCount: 4),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildCompactFAQItem(faqs[index]),
                );
              }, childCount: faqs.length),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              32,
            ), // Extra bottom padding
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const Text(
                    "Ready to improve your goat farm?",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: _buildPillButton(
                      text: 'Start Free Trial',
                      onPressed: () => _navigateToSignup(context),
                      isFilled: true,
                      width: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String text,
    required VoidCallback onPressed,
    required bool isFilled,
    double width = 120,
  }) {
    return SizedBox(
      width: width,
      child: isFilled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white)),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(text, style: const TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildCompactFeatureCard(FeatureItem feature) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature.icon, size: 30, color: feature.color),
            const SizedBox(height: 8),
            Text(
              feature.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              feature.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactFAQItem(FAQItem faq) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          faq.question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              faq.answer,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.pushNamed(context, '/farm/signup');
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/farm/login');
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
