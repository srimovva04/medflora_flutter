import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../plant_identification/functionality_page.dart';
import 'specialist_page.dart';
import '../auth/providers/auth_provider.dart';
import '../core/role_page.dart';

class SpecialistDashboardPage extends StatelessWidget {
  const SpecialistDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(

        appBar: AppBar(
          title: const Text(
            "Specialist Panel",
            style: TextStyle(fontSize: 16),
          ),

          toolbarHeight: 33, // ✅ smaller appbar height

          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 20),
              tooltip: "Logout",
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Do you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;

                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout();

                if (!context.mounted) return;

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
                      (_) => false,
                );
              },
            )
          ],

          bottom: const TabBar(
            labelPadding: EdgeInsets.symmetric(vertical: 2),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 20),
                    SizedBox(width: 6),
                    Text("User Tools"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, size: 20),
                    SizedBox(width: 6),
                    Text("Curator Tools"),
                  ],
                ),
              ),
            ],
          ),

        ),

        body: const TabBarView(
          children: [
            FunctionalityPage(showAppBar: false),
            SpecialistPage(showAppBar: false),
          ],
        ),
      ),
    );
  }
}

class NoAppBar extends StatelessWidget {
  final Widget child;

  const NoAppBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (child is Scaffold) {
      final s = child as Scaffold;

      return MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Scaffold(
          body: s.body,
          bottomNavigationBar: s.bottomNavigationBar,
          floatingActionButton: s.floatingActionButton,
        ),
      );
    }

    return child;
  }
}
