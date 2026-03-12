import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateAndPrintInvoice({
    required String invoiceNo,
    required String orderNo,
    required String buyerName,
    required List<dynamic> items,
    required double subTotal,
    required double tax,
    required double grandTotal,
    required Map<String, String> companyDetails,
    required Map<String, String> bankDetails,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),
        build: (pw.Context context) {
          return pw.Container(
            height: 760,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [
                // 1. HEADER
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          children: [
                            pw.Text(
                              companyDetails['name'] ?? "",
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              companyDetails['tagline'] ?? "",
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              companyDetails['address'] ?? "",
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                            pw.Text(
                              "GSTIN: ${companyDetails['gstin']}",
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildTaxInvoiceLabel(),
                  ],
                ),
                pw.Divider(height: 0),

                // 2. INFO SECTION (Right side headers fixed)
                _buildInfoSection(buyerName, orderNo, invoiceNo),
                pw.Divider(height: 0),

                // 3. ITEMS TABLE
                _buildItemsTable(items),

                // 4. FOOTER (Bank, Words, Totals, Certificate & Signature)
                pw.Divider(height: 0),
                pw.Container(
                  height: 120, // Increased height slightly to fit the signature
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Expanded(
                        flex: 6,
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Bank Name : ${bankDetails['bankName']}",
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                              pw.Text(
                                "Ac. No. : ${bankDetails['accountNo']}  IFSC : ${bankDetails['ifsc']}",
                                style: const pw.TextStyle(fontSize: 8),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                "RUPEES ${_amountToWords(grandTotal.toInt())} ONLY",
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                "CERTIFICATE",
                                style: pw.TextStyle(
                                  fontSize: 7,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                "Certified that the particulars given above are true and correct and the amount indicated represents the price actually charged.",
                                style: const pw.TextStyle(fontSize: 6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.Container(width: 1, color: PdfColors.black),

                      // Right Side: Totals + Signature Section
                      pw.Expanded(
                        flex: 4,
                        child: pw.Column(
                          children: [
                            // Reusing your totals logic here
                            _totalRow("TOTAL", subTotal),
                            _totalRow("SGST 2.5%", tax / 2),
                            _totalRow("CGST 2.5%", tax / 2),
                            _totalRow("ROUND OFF", 0.00),
                            pw.Divider(height: 1, thickness: 0.5),
                            pw.Container(
                              color: PdfColors.grey200,
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    "GRAND TOTAL",
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.Text(
                                    grandTotal.toStringAsFixed(2),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            pw.Spacer(),
                            // SIGNATURE SECTION
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(
                                bottom: 5,
                                right: 5,
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    "For ${companyDetails['name']}",
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(
                                    height: 25,
                                  ), // Space for physical signature/seal
                                  pw.Text(
                                    "Authorised Signatory",
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Widget _buildTaxInvoiceLabel() {
    return pw.Container(
      width: 120,
      height: 60,
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey300,
        border: pw.Border(
          left: pw.BorderSide(width: 1),
          bottom: pw.BorderSide(width: 1),
        ),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        "TAX INVOICE",
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
      ),
    );
  }

  static pw.Widget _buildInfoSection(String buyer, String order, String inv) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 5,
          child: pw.Container(
            height: 90,
            padding: const pw.EdgeInsets.all(4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(width: 1)),
            ),
            child: pw.Text(
              "Name & Address of the Consignee:\n$buyer",
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ),
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            children: [
              _splitRow("ORDER No.", order),
              _splitRow("INVOICE No.", inv),
              _splitRow(
                "DATE",
                DateFormat('dd-MM-yyyy').format(DateTime.now()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _splitRow(String label, String value) {
    return pw.Container(
      height: 30,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 4),
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
            ),
          ),
          pw.Container(width: 1, height: 30, color: PdfColors.black),
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<dynamic> items) {
    return pw.Container(
      height: 440,
      child: pw.Table(
        border: const pw.TableBorder(verticalInside: pw.BorderSide(width: 0.5)),
        columnWidths: {
          0: const pw.FixedColumnWidth(25),
          1: const pw.FlexColumnWidth(2),
          7: const pw.FixedColumnWidth(65),
        },
        children: [
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey100),
            children:
                [
                      'S.No',
                      'Description',
                      'HSN',
                      'Box',
                      'Mts',
                      'Total Qty',
                      'Rate',
                      'Total Value',
                    ]
                    .map(
                      (h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(3),
                        child: pw.Text(
                          h,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    )
                    .toList(),
          ),
          ...items.asMap().entries.map((e) {
            double qty = (e.value.boxes ?? 0) * (e.value.mts ?? 0.0);
            return pw.TableRow(
              children: [
                _cell((e.key + 1).toString()),
                _cell(e.value.description ?? "", align: pw.TextAlign.left),
                _cell("60"),
                _cell(e.value.boxes.toString()),
                _cell(e.value.mts.toString()),
                _cell(qty.toStringAsFixed(2)),
                _cell(e.value.rate.toStringAsFixed(2)),
                _cell((qty * e.value.rate).toStringAsFixed(2)),
              ],
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalsSection(double s, double t, double g) {
    return pw.Expanded(
      flex: 4,
      child: pw.Column(
        children: [
          _totalRow("TOTAL", s),
          _totalRow("SGST 2.5%", t / 2),
          _totalRow("CGST 2.5%", t / 2),
          _totalRow("ROUND OFF", 0.00),
          pw.Spacer(),
          pw.Container(
            color: PdfColors.grey200,
            padding: const pw.EdgeInsets.all(4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "GRAND TOTAL",
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  g.toStringAsFixed(2),
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String l, double v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(v.toStringAsFixed(2), style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _cell(
    String t, {
    pw.TextAlign align = pw.TextAlign.center,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(t, style: const pw.TextStyle(fontSize: 8), textAlign: align),
  );

  // RESTORED: Amount to words logic
  static String _amountToWords(int amount) {
    if (amount == 0) return "ZERO";
    var units = [
      "",
      "ONE",
      "TWO",
      "THREE",
      "FOUR",
      "FIVE",
      "SIX",
      "SEVEN",
      "EIGHT",
      "NINE",
      "TEN",
      "ELEVEN",
      "TWELVE",
      "THIRTEEN",
      "FOURTEEN",
      "FIFTEEN",
      "SIXTEEN",
      "SEVENTEEN",
      "EIGHTEEN",
      "NINETEEN",
    ];
    var tens = [
      "",
      "",
      "TWENTY",
      "THIRTY",
      "FORTY",
      "FIFTY",
      "SIXTY",
      "SEVENTY",
      "EIGHTY",
      "NINETY",
    ];

    String convert(int n) {
      if (n < 20) return units[n];
      if (n < 100)
        return "${tens[n ~/ 10]}${n % 10 != 0 ? " ${units[n % 10]}" : ""}";
      if (n < 1000)
        return "${units[n ~/ 100]} HUNDRED${n % 100 != 0 ? " AND ${convert(n % 100)}" : ""}";
      if (n < 100000)
        return "${convert(n ~/ 1000)} THOUSAND${n % 1000 != 0 ? " ${convert(n % 1000)}" : ""}";
      if (n < 10000000)
        return "${convert(n ~/ 100000)} LAKH${n % 100000 != 0 ? " ${convert(n % 100000)}" : ""}";
      return "";
    }

    return convert(amount);
  }
}
