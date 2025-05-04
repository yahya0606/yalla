import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:louage/features/auth/domain/models/user_model.dart';
import 'package:louage/features/auth/providers/auth_service_provider.dart';
import 'package:louage/features/auth/providers/current_user_provider.dart';
import 'package:louage/features/shared/providers/wallet_provider.dart';
import 'package:louage/features/shared/presentation/screens/settings_screen.dart';
import 'package:louage/features/passenger/presentation/screens/bookings_screen.dart';
import 'package:louage/features/driver/presentation/screens/driver_availability_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.value;

    // Ensure walletAsync is null when user is null, and handle null cases
    final walletAsync = user != null ? ref.watch(userWalletProvider(user.uid)) : null;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    child: Text(
                      // Check if user?.name is not null and not empty
                      (user?.name?.isNotEmpty ?? false) ? user!.name![0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Loading...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user != null) ...[
                    Text(
                      user.email ?? 'No Email',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (walletAsync != null) ...[
                      // Display the wallet balance if it's available
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            // Show wallet balance, default to "0.00" if null
                            Text(
                              '${walletAsync?.value?.balance?.toStringAsFixed(2) ?? "0.00"} TND',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ],
              ),
            ),
          ),
          if (user?.role == UserRole.driver) ...[
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('My Availability'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverAvailabilityScreen(),
                  ),
                );
              },
            ),
          ] else ...[
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('My Bookings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingsScreen(),
                ),
              );
            },
          ),
          ],
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Top Up Wallet'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to top up screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              try {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
