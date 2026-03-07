import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/parking_provider.dart';
import '../widgets/glass_card.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<ParkingProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Wallet'), centerTitle: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add Card Feature Coming Soon!')),
          );
        },
        child: const Icon(Icons.add),
      ).animate().scale(curve: Curves.easeOutBack),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassCard(
                  height: 260,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade800,
                          Colors.deepPurpleAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(
                              Icons.credit_card,
                              color: Colors.white,
                              size: 32,
                            ).animate().rotate(
                              delay: 500.milliseconds,
                              duration: 1.seconds,
                            ),
                            Text(
                              'Primary',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '**** **** **** 4242',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ).animate().shimmer(
                          delay: 1.seconds,
                          duration: 2.seconds,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'JOHN DOE',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '12/25',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 600.milliseconds)
                .slideY(begin: 0.2, curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            Text(
              'Payment Methods',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 300.milliseconds).slideX(begin: -0.1),
            const SizedBox(height: 16),
            ...provider.paymentMethods.asMap().entries.map((entry) {
              final index = entry.key;
              final method = entry.value;
              return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: method.color.withOpacity(0.1),
                      child: Icon(method.icon, color: method.color),
                    ),
                    title: Text(
                      method.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: method.details != null
                        ? Text(method.details!)
                        : null,
                    trailing: const Icon(Icons.chevron_right),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onTap: () {},
                  )
                  .animate(delay: (400 + (index * 100)).milliseconds)
                  .fadeIn()
                  .slideX(begin: 0.1);
            }),
          ],
        ),
      ),
    );
  }
}
