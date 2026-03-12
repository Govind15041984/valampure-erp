import 'package:flutter/material.dart';
import '../../../api/sales_api.dart';
import 'sales_detail_view_screen.dart';
import 'sales_entry_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  bool _isHistoryMode = false;
  bool _isLoading = false;
  List<dynamic> _sales = [];

  @override
  void initState() {
    super.initState();
    _fetchSales();
  }

  Future<void> _fetchSales() async {
    setState(() => _isLoading = true);
    try {
      final data = await SalesApi.getSalesList(historyMode: _isHistoryMode);
      setState(() {
        _sales = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      debugPrint("DEBUG: _fetchSales Screen Error -> $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F), // Dark Slate Gray
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sales Registry",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              _isHistoryMode
                  ? "Showing: Full History"
                  : "Showing: Current Month",
              style: const TextStyle(fontSize: 11, color: Colors.orangeAccent),
            ),
          ],
        ),
        actions: [
          const Center(
            child: Text(
              "History",
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ),
          Switch(
            value: _isHistoryMode,
            activeColor: Colors.orange,
            onChanged: (val) {
              setState(() => _isHistoryMode = val);
              _fetchSales();
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSales),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => const SalesEntryScreen()),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Forest Green
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSales,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _sales.isEmpty
            ? _buildEmptyState()
            : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _sales.length,
      itemBuilder: (context, index) {
        final sale = _sales[index];

        // --- DATA MAPPING (Matches your SQLAlchemy Model) ---
        final String invNo = sale['invoice_number'] ?? "N/A";
        final String date = sale['invoice_date']?.toString() ?? "No Date";
        final bool isGst = sale['is_gst'] ?? true;

        // Handle nested Partner Object or flat field
        final String buyer =
            (sale['partner']?['name'] ??
                    sale['partner_name'] ??
                    "Unknown Buyer")
                .toString()
                .toUpperCase();

        // Convert Numeric/String from API to double safely
        final double grandTotal =
            double.tryParse(sale['grand_total']?.toString() ?? '0') ?? 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: isGst ? Colors.blue : Colors.orange,
                width: 5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SalesDetailView(saleId: sale['id'].toString()),
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "INV: $invNo",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "₹ ${grandTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    buyer,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        size: 12,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isGst ? Colors.blue[50] : Colors.orange[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isGst ? "GST" : "NON-GST",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isGst
                                ? Colors.blue[800]
                                : Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      // Wrap in ListView to allow RefreshIndicator to work
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              const Text(
                "No Sales Recorded Yet",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                "Toggle History or use + to add one",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
