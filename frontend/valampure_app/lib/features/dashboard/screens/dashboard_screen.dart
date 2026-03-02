import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../auth/screens/mobile_screen.dart';
import '../../../core/auth_storage.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthStorage.instance.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MobileScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we are on a wide screen (Laptop/Desktop)
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar (Navigation)
          if (isDesktop)
            Container(
              width: 250,
              color: AppColors.primary,
              child: _buildSidebar(context),
            ),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isDesktop),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    color: AppColors.background,
                    child: _buildDummyContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Mobile Drawer if screen is small
      drawer: !isDesktop ? Drawer(child: _buildSidebar(context)) : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Column(
      children: [
        const DrawerHeader(
          child: Center(
            child: Text(
              "VALAMPURE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        _sidebarItem(Icons.dashboard, "Dashboard", active: true),
        _sidebarItem(Icons.receipt_long, "Billing"),
        _sidebarItem(Icons.inventory, "Stock"),
        _sidebarItem(Icons.people, "Customers"),
        const Spacer(),
        _sidebarItem(
          Icons.logout,
          "Logout",
          onTap: () => _handleLogout(context),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _sidebarItem(
    IconData icon,
    String title, {
    bool active = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: active ? AppColors.accent : Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: active ? Colors.white : Colors.white70),
      ),
      onTap: onTap,
      tileColor: active ? Colors.white.withOpacity(0.1) : Colors.transparent,
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          const Text(
            "Main Dashboard",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none),
          const SizedBox(width: 20),
          const CircleAvatar(
            backgroundColor: AppColors.accent,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDummyContent() {
    return GridView.count(
      crossAxisCount: 4, // 4 items in a row for Desktop
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      childAspectRatio: 1.5,
      children: [
        _statCard("Total Sales", "₹ 45,000", Icons.trending_up, Colors.blue),
        _statCard("Total Bills", "128", Icons.description, Colors.orange),
        _statCard("Active Items", "452", Icons.category, Colors.purple),
        _statCard("Support Expiry", "364 Days", Icons.timer, Colors.red),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
