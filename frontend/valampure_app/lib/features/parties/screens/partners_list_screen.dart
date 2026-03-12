import 'package:flutter/material.dart';
import 'package:valampure_app/features/parties/screens/partner_ledger_screen.dart';
import '../../../api/partners_api.dart';
import 'add_partner_screen.dart';

class PartnersListScreen extends StatefulWidget {
  const PartnersListScreen({super.key});

  @override
  State<PartnersListScreen> createState() => _PartnersListScreenState();
}

class _PartnersListScreenState extends State<PartnersListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshCounter = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the controller with 2 tabs
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Partners & Directory"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_cart), text: "Suppliers"),
            Tab(icon: Icon(Icons.person), text: "Buyers"),
          ],
        ),
      ),
      // ValueKey ensures the FutureBuilder re-runs on refresh
      body: TabBarView(
        controller: _tabController,
        key: ValueKey(_refreshCounter),
        children: const [
          PartnerTab(type: "SUPPLIER"),
          PartnerTab(type: "BUYER"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // DYNAMIC TYPE: Determine type based on active tab index
          // Index 0 = SUPPLIER, Index 1 = BUYER
          String currentType = _tabController.index == 0 ? "SUPPLIER" : "BUYER";

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPartnerScreen(initialType: currentType),
            ),
          );

          if (result == true) {
            setState(() {
              _refreshCounter++;
            });
          }
        },
        label: const Text("Add Partner"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class PartnerTab extends StatelessWidget {
  final String type;
  const PartnerTab({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: PartnersApi.getPartners(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No ${type.toLowerCase()}s added yet."));
        }

        final partners = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => (context as Element).markNeedsBuild(),
          child: ListView.builder(
            itemCount: partners.length,
            itemBuilder: (context, index) {
              final item = partners[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: type == "SUPPLIER"
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    child: Text(item['name'][0].toUpperCase()),
                  ),
                  title: Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(item['mobile_number'] ?? 'No Mobile Number'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Balance",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        "₹${item['current_balance']}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          //color: (item['current_balance'] > 0)
                          //    ? Colors.red
                          //    : Colors.green,
                          color: type == "SUPPLIER" ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PartnerLedgerScreen(
                          partnerId: item['id'],
                          partnerName: item['name'],
                          partnerType: type, // "SUPPLIER" or "BUYER"
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
