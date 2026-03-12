import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../api/dashboard_api.dart';
import '../../../core/auth_storage.dart';
import '../../auth/screens/mobile_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../parties/screens/partners_list_screen.dart';
import '../../purchase/screens/purchase_entry_screen.dart';
import '../../sales/screens/sales_entry_screen.dart';
import '../../manufacturing/screens/production_log_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = DashboardApi.getSummary();
  }

  void _refreshData() {
    setState(() {
      _dashboardData = DashboardApi.getSummary();
    });
  }

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
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildTopBar(context, isDesktop),
      drawer: !isDesktop
          ? Drawer(
              child: Container(
                color: const Color(0xFF37474F),
                child: _buildSidebar(context, isDesktop),
              ),
            )
          : null,
      floatingActionButton: _buildStackedFABs(context, isDesktop),
      body: Row(
        children: [
          if (isDesktop) _buildFloatingSidebar(context, isDesktop),
          Expanded(
            child: Container(
              margin: isDesktop ? const EdgeInsets.all(16) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isDesktop
                    ? BorderRadius.circular(24)
                    : BorderRadius.zero,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RefreshIndicator(
                  onRefresh: () async => _refreshData(),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _dashboardData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      final data = snapshot.data!;
                      final growth = data['growth'] ?? {};
                      final pulse = data['pulse'] ?? {};
                      final finance = data['finance'] ?? {};

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(
                          24,
                        ), // Tighter padding for density
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader("Financial & Sales Overview"),
                            const SizedBox(height: 12),
                            _buildGrowthFinanceGrid(finance, growth, isDesktop),

                            if (pulse['critical_stock'] != null &&
                                pulse['critical_stock'].isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildSectionHeader("Critical Stock Alerts ⚠️"),
                              const SizedBox(height: 8),
                              _buildAlertBanner(pulse['critical_stock']),
                            ],

                            const SizedBox(height: 32),

                            // CONTENT HEAVY SECTION: Charts and Stock Side-by-Side on Desktop
                            if (isDesktop)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader(
                                          "Operational Pulse (Prod vs Sales)",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildGapChart(pulse['gap_data'] ?? []),
                                        const SizedBox(height: 32),
                                        _buildSectionHeader(
                                          "Expense Breakdown by Category",
                                        ),
                                        const SizedBox(height: 12),
                                        _buildExpenseBreakdown(
                                          finance['expense_breakdown'] ?? [],
                                        ),
                                        const SizedBox(height: 32),
                                        _buildSplitLists(
                                          growth['top_customers'] ?? [],
                                          data['recent_purchases'] ?? [],
                                          isDesktop,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildSectionHeader("Stock in Hand"),
                                        const SizedBox(height: 12),
                                        _buildStockGrid(
                                          data['stock'] ?? [],
                                          isDesktop,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              _buildSectionHeader(
                                "Operational Pulse (Prod vs Sales)",
                              ),
                              const SizedBox(height: 12),
                              _buildGapChart(pulse['gap_data'] ?? []),
                              const SizedBox(height: 32),
                              _buildSectionHeader("Stock in Hand"),
                              const SizedBox(height: 12),
                              _buildStockGrid(data['stock'] ?? [], isDesktop),
                              const SizedBox(height: 32),
                              _buildSplitLists(
                                growth['top_customers'] ?? [],
                                data['recent_purchases'] ?? [],
                                isDesktop,
                              ),
                            ],
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED: DENSE DUAL BAR CHART (FIXES MISSING SALES) ---
  Widget _buildExpenseBreakdown(List breakdown) {
    if (breakdown.isEmpty) {
      return _buildEmptyState("No expenses recorded for this month.");
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        // Using Wrap helps it look good on both mobile and desktop
        spacing: 20,
        runSpacing: 10,
        children: breakdown.map((item) {
          return SizedBox(
            width: 150, // Fixed width for a neat grid look
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['category'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${item['amount']}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGapChart(List gapData) {
    if (gapData.isEmpty) {
      return _buildEmptyState("No recent activity found.");
    }

    return Container(
      height: 280, // Content heavy height
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _chartLegend("Production", const Color(0xFF37474F)),
              const SizedBox(width: 15),
              _chartLegend("Sales", Colors.orange),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        if (val.toInt() >= gapData.length)
                          return const Text("");
                        return Text(
                          gapData[val.toInt()]['date'].split('-').last,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: gapData.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: (e.value['prod'] ?? 0).toDouble(),
                        color: const Color(0xFF37474F),
                        width: 14, // Increased width for density
                        borderRadius: BorderRadius.circular(2),
                      ),
                      BarChartRodData(
                        toY: (e.value['sales'] ?? 0).toDouble(),
                        color: Colors.orange,
                        width: 14, // Increased width for density
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- GROWTH & FINANCE GRID (STRICT NULL SAFETY) ---
  Widget _buildGrowthFinanceGrid(Map finance, Map growth, bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 5 : 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: isDesktop ? 2.0 : 1.4,
      children: [
        _statCard(
          "Receivable",
          "₹${finance['receivable'] ?? 0}",
          Icons.payments,
          Colors.green,
          subtitle: "Overdue: ₹${finance['overdue_30_days'] ?? 0}",
        ),
        _statCard(
          "Payable",
          "₹${finance['payable'] ?? 0}",
          Icons.outbox,
          Colors.red,
        ),
        _statCard(
          "Net Cash",
          "₹${finance['net_balance'] ?? 0}",
          Icons.account_balance_wallet,
          Colors.blueGrey,
          // NEW: Adding a subtitle to show total spent this month
          subtitle: "Monthly Expenses: ₹${finance['monthly_expenses'] ?? 0}",
        ),
        _statCard(
          "Today Sales",
          "${growth['today_count'] ?? 0} Bills",
          Icons.receipt_long,
          Colors.blue,
        ),
        _statCard(
          "Vs Yesterday",
          "${growth['yesterday_count'] ?? 0} Bills",
          Icons.history,
          Colors.orange,
        ),
      ],
    );
  }

  // --- REUSED COMPONENTS WITH OPTIMIZED STYLES ---

  Widget _chartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _buildAlertBanner(List critical) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: critical.length,
        itemBuilder: (context, index) {
          final item = critical[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Center(
              child: Text(
                "${item['size']}MM: ${item['boxes']} BOXES",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSplitLists(List customers, List purchases, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Top Customers"),
                  const SizedBox(height: 8),
                  _buildDataList(customers, Icons.person, Colors.blue),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Recent Purchases"),
                  const SizedBox(height: 8),
                  _buildDataList(
                    purchases,
                    Icons.shopping_cart,
                    Colors.green,
                    isPurchase: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataList(
    List items,
    IconData icon,
    Color color, {
    bool isPurchase = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (c, i) => const Divider(height: 1, indent: 45),
        itemBuilder: (c, i) {
          final item = items[i];
          return ListTile(
            dense: true,
            leading: Icon(icon, color: color, size: 16),
            title: Text(
              isPurchase ? "Bill: ${item['bill']}" : "${item['name']}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              "₹${item['amount']}",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockGrid(List stock, bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stock.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = stock[index];
        final bool isLow = (item['boxes'] ?? 0) <= 0;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLow ? Colors.red[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLow ? Colors.red.shade100 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${item['size']} MM ${item['description']}",
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${item['boxes']} Box",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isLow ? Colors.red : Colors.black,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Text(
    title.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Color(0xFF37474F),
      letterSpacing: 0.5,
    ),
  );

  // --- UI FRAMEWORK (SIDEBARS & TOPBAR) ---

  Widget _buildFloatingSidebar(BuildContext context, bool isDesktop) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF37474F),
          borderRadius: BorderRadius.circular(24),
        ),
        child: _buildSidebar(context, isDesktop),
      ),
    );
  }

  PreferredSizeWidget _buildTopBar(BuildContext context, bool isDesktop) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF37474F),
      centerTitle: true,
      title: const Text(
        "VALAMPURI ELASTICS",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _refreshData,
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        const SizedBox(height: 20),

        // 1. DASHBOARD
        _sidebarItem(
          Icons.grid_view_rounded,
          "Dashboard",
          active: true,
          onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),

        // 2. PARTIES
        _sidebarItem(
          Icons.people_outline,
          "Parties",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PartnersListScreen()),
          ),
        ),

        // 3. PURCHASE
        _sidebarItem(
          Icons.shopping_bag_outlined,
          "Purchase",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PurchaseEntryScreen(),
            ),
          ),
        ),

        // 4. MANUFACTURING
        _sidebarItem(
          Icons.precision_manufacturing_outlined,
          "Manufacturing",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProductionLogScreen()),
          ),
        ),

        // 5. BILLING (SALES)
        _sidebarItem(
          Icons.receipt_long_outlined,
          "Billing",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SalesEntryScreen()),
          ),
        ),

        // 6. EXPENSES (NEWLY HOOKED)
        _sidebarItem(
          Icons.money_off_rounded,
          "Expenses",
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpensesScreen()),
          ),
        ),

        // 7. SALARY & STAFF (DUMMY)
        _sidebarItem(
          Icons.badge_outlined,
          "Salary & Staff",
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Salary module coming soon!")),
            );
          },
        ),

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
      leading: Icon(
        icon,
        color: active ? Colors.orange : Colors.white70,
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: active ? Colors.white : Colors.white70,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStackedFABs(BuildContext context, bool isDesktop) {
    if (isDesktop) return const SizedBox.shrink();
    return FloatingActionButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SalesEntryScreen()),
      ),
      backgroundColor: Colors.green,
      child: const Icon(Icons.add),
    );
  }
}
