import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PdfService {
  static Future<void> generateAndPrintInvoice({
    required String invoiceNo,
    required String orderNo,
    required String buyerName,
    required String buyerGST,
    required String buyerState,
    required String buyerStateCode,
    required List<dynamic> items,
    required double subTotal,
    required double tax,
    required double grandTotal,
    required Map<String, String> company,
    required Map<String, String> bank,
  }) async {
    final pdf = pw.Document();
    final fontData = await rootBundle.load("assets/fonts/valampure.ttf");
    final headerFont = pw.Font.ttf(fontData);
    final logoImage = pw.MemoryImage(
      (await rootBundle.load(
        'assets/images/Valampure-logo.jpeg',
      )).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          double totalMts = 0;
          for (var i in items) {
            // Using bracket notation [] for Maps
            double boxes = double.tryParse(i['boxes']?.toString() ?? '0') ?? 0;
            double mts = double.tryParse(i['mts']?.toString() ?? '0') ?? 0;
            totalMts += (boxes * mts);
          }

          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [
                _header(company, invoiceNo, headerFont, logoImage),

                _gstSection(company, orderNo, invoiceNo),

                _consigneeSection(
                  buyerName,
                  buyerGST,
                  buyerState,
                  buyerStateCode,
                ),

                _itemsTable(items, totalMts),

                _bankAndTotal(bank, subTotal, tax, grandTotal),

                _certificate(),

                _conditions(),

                //pw.Spacer(),
                pw.SizedBox(height: 10),

                _bottomSign(company),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  /// HEADER
  static pw.Widget _header(
    Map<String, String> c,
    String invoiceNo,
    pw.Font headerFont,
    pw.MemoryImage logoImage,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 70,
            height: 70,
            child: pw.Center(
              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
            ),
          ),

          pw.SizedBox(width: 10),

          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  c['name'] ?? "VALAMPURE ELASTICS",
                  style: pw.TextStyle(
                    font: headerFont,
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.Text(
                  "Manufacturers And Suppliers Of Imported Rubber Elastic Tapes",
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.Text(c['address1'] ?? "", style: pw.TextStyle(fontSize: 10)),

                pw.Text(c['address2'] ?? "", style: pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),

          pw.Container(
            width: 120,
            child: pw.Column(
              children: [
                pw.Container(
                  color: PdfColors.black,
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Center(
                    child: pw.Text(
                      "TAX INVOICE",
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text("S.No."), pw.Text(invoiceNo)],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Date"),
                    pw.Text(DateFormat("dd-MM-yyyy").format(DateTime.now())),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// GST + ORDER SECTION
  static pw.Widget _gstSection(
    Map<String, String> company,
    String orderNo,
    String invoiceNo,
  ) {
    return pw.Container(
      height: 60,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(width: 1),
          bottom: pw.BorderSide(width: 1),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text("GSTIN : ${company['gstin'] ?? ''}"),
                  pw.Text("State Code : ${company['stateCode'] ?? ''}"),
                  pw.Text("Area Code : ${company['areaCode'] ?? ''}"),
                ],
              ),
            ),
          ),

          pw.Container(width: 1, color: PdfColors.black),

          pw.Expanded(
            flex: 4,
            child: pw.Column(
              children: [
                _infoRow("ORDER NO", orderNo),
                _infoRow("INVOICE NO", invoiceNo),
                _infoRow(
                  "DATE",
                  DateFormat("dd-MM-yyyy").format(DateTime.now()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(String l, String v) {
    return pw.Container(
      height: 20,
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(l),
            ),
          ),

          pw.Container(width: 1, color: PdfColors.black),

          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                v,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// CONSIGNEE + SEAL
  static pw.Widget _consigneeSection(
    String buyer,
    String gst,
    String state,
    String code,
  ) {
    return pw.Container(
      height: 90,
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(width: 1)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Name & Address of the Consignee",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),

                  pw.SizedBox(height: 5),

                  pw.Text(buyer),
                  pw.Text("GSTIN : $gst"),
                  pw.Text("State : $state"),
                  pw.Text("Code : $code"),
                ],
              ),
            ),
          ),

          pw.Expanded(flex: 4, child: pw.Center(child: _sealSection())),
        ],
      ),
    );
  }

  static pw.Widget _sealSection() {
    // Increased size and adjusted thickness for better proportion
    const double stampSize = 75.0;
    const double ringThickness = 16.0;

    return pw.Center(
      child: pw.Container(
        width: stampSize,
        height: stampSize,
        decoration: const pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: PdfColors.black,
        ),
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            // CENTER WHITE HOLE
            pw.Container(
              width: stampSize - (ringThickness * 2),
              height: stampSize - (ringThickness * 2),
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                shape: pw.BoxShape.circle,
              ),
            ),

            // WHITE TEXT - Anti-clockwise
            ..._getAntiClockwiseText(
              " VALAMPURE ELASTICS ",
              // Radius is half-diameter minus half-thickness to center text in the black band
              radius: (stampSize / 2) - (ringThickness / 2),
              color: PdfColors.white,
            ),
          ],
        ),
      ),
    );
  }

  static List<pw.Widget> _getAntiClockwiseText(
    String text, {
    required double radius,
    required PdfColor color,
  }) {
    final List<pw.Widget> widgets = [];
    final double angleStep = (2 * pi) / text.length;

    for (int i = 0; i < text.length; i++) {
      // Negative logic for anti-clockwise flow
      final double angle = -(i * angleStep) - (pi / 2);

      widgets.add(
        pw.Transform(
          transform: Matrix4.identity()
            ..translate(radius * cos(angle), radius * sin(angle))
            ..rotateZ(angle + (pi / 2)),
          alignment: pw.Alignment.center,
          child: pw.Text(
            text[i],
            style: pw.TextStyle(
              color: color,
              fontSize: 6.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  static List<pw.Widget> _getCircularText(
    String text, {
    required double radius,
    required PdfColor color,
  }) {
    final List<pw.Widget> widgets = [];
    final double angleStep = (2 * pi) / text.length;

    for (int i = 0; i < text.length; i++) {
      // We subtract pi/2 to start from the top center
      final double angle = (i * angleStep) - (pi / 2);

      widgets.add(
        pw.Transform(
          transform: Matrix4.identity()
            ..translate(radius * cos(angle), radius * sin(angle))
            ..rotateZ(angle + (pi / 2)), // Rotates character to face outward
          alignment: pw.Alignment.center,
          child: pw.Text(
            text[i],
            style: pw.TextStyle(
              color: color,
              fontSize: 6,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  /// ITEMS TABLE
  static pw.Widget _itemsTable(List items, double totalMts) {
    const int maxRows = 8;
    int emptyRows = maxRows - items.length;

    List<pw.TableRow> rows = [];

    // Header Row - Exactly as your template
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide()),
        ),
        children: [
          _th("S.No."),
          _th("Description of Goods"),
          _th("HSN Code"),
          _th("Box"),
          _th("MTS"),
          _th("Total Qty"),
          _th("Rate"),
          _th("Total Value"),
        ],
      ),
    );

    // Data Rows - Accessing Map keys correctly
    for (var e in items.asMap().entries) {
      final item = e.value;

      double boxes = double.tryParse(item['boxes']?.toString() ?? '0') ?? 0;
      double mts = double.tryParse(item['mts']?.toString() ?? '0') ?? 0;
      double rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;

      double qty = boxes * mts;
      double total = qty * rate;

      rows.add(
        pw.TableRow(
          children: [
            _td("${e.key + 1}"),
            _td(
              item['description']?.toString() ?? "",
            ), // Dynamic: No hardcoded prefix
            _td(item['hsn']?.toString() ?? ""), // Dynamic: No hardcoded HSN
            _td(boxes.toStringAsFixed(0)),
            _td(mts.toStringAsFixed(0)),
            _td(qty.toStringAsFixed(0)),
            _td(rate.toString()),
            _td(total.toStringAsFixed(2)),
          ],
        ),
      );
    }

    // Empty Rows - Maintains the template look
    for (int i = 0; i < emptyRows; i++) {
      rows.add(
        pw.TableRow(
          children: List.generate(8, (index) => pw.Container(height: 20)),
        ),
      );
    }

    // Total Row
    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
        children: [
          _td(""),
          _td("TOTAL MTS"),
          _td(""),
          _td(""),
          _td(""),
          _td(totalMts.toStringAsFixed(0)),
          _td(""),
          _td(""),
        ],
      ),
    );

    return pw.Table(
      border: pw.TableBorder(
        left: pw.BorderSide(),
        right: pw.BorderSide(),
        top: pw.BorderSide(),
        bottom: pw.BorderSide(),
        verticalInside: pw.BorderSide(), // Keeps original vertical column lines
      ),
      children: rows,
    );
  }

  /// BANK + TOTAL
  /// BANK + TOTAL SECTION (FIXED & TESTED)
  static pw.Widget _bankAndTotal(
    Map<String, String> bank,
    double sub,
    double tax,
    double grand,
  ) {
    return pw.Row(
      // Removed pw.IntrinsicHeight
      crossAxisAlignment: pw.CrossAxisAlignment.start, // Align to top
      children: [
        // LEFT COLUMN: Bank Details + Amount in Words
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            // Set a fixed height if you want it to look exactly like the sample
            height: 100,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(width: 1),
                bottom: pw.BorderSide(width: 1),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Bank Name : ${bank['bankName'] ?? ''}"),
                      pw.Text("Ac No : ${bank['accountNo'] ?? ''}"),
                      pw.Text("IFSC Code : ${bank['ifsc'] ?? ''}"),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(width: 1)),
                  ),
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Text(
                    "RUPEES ${_amountToWords(grand.toInt())} ONLY",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // RIGHT COLUMN: Tax Summary Table
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            height: 100, // Matches the left side height
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            child: pw.Column(
              children: [
                _totalRow("TOTAL", sub),
                _totalRow("SGST 2.5%", tax / 2),
                _totalRow("CGST 2.5%", tax / 2),
                _totalRow("ROUND OFF", 0),
                pw.Expanded(
                  child: pw.Container(
                    alignment: pw.Alignment.bottomCenter,
                    child: _totalRow("GRAND TOTAL", grand, isBold: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _amountWords(double grand) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        "RUPEES ${_amountToWords(grand.toInt())} ONLY",
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      ),
    );
  }

  static String _amountToWords(int number) {
    final units = [
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

    final tens = [
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

      if (n < 100) {
        return tens[n ~/ 10] + (n % 10 != 0 ? " ${units[n % 10]}" : "");
      }

      if (n < 1000) {
        return "${units[n ~/ 100]} HUNDRED ${convert(n % 100)}";
      }

      if (n < 100000) {
        return "${convert(n ~/ 1000)} THOUSAND ${convert(n % 1000)}";
      }

      if (n < 10000000) {
        return "${convert(n ~/ 100000)} LAKH ${convert(n % 100000)}";
      }

      return "";
    }

    return convert(number).replaceAll(RegExp(' +'), ' ').trim();
  }

  static pw.Widget _certificate() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        //pw.Divider(),
        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Text(
            "CERTIFICATE",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),

        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5),
          child: pw.Text(
            "Certified that the particular are true and correct and the amount indicated in this document represents the price actually charged by us and there is no additional consideration flowing directly or indirectly from such sales over and above what has been declared.",
            style: pw.TextStyle(fontSize: 9),
          ),
        ),
      ],
    );
  }

  static pw.Widget _conditions() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),

        pw.Padding(
          padding: const pw.EdgeInsets.all(5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("1. Subject to Tiruppur Jurisdictions."),
              pw.Text("2. We are not responsible for any loss or Damage."),
              pw.Text("3. Goods supplied under firm conditions"),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _bottomSign(Map<String, String> company) {
    return pw.Column(
      children: [
        pw.Divider(),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 5),
              child: pw.Text("E. & O.E"),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 5),
              child: pw.Text("For ${company['name']}"),
            ),
          ],
        ),

        pw.SizedBox(height: 25),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 5, bottom: 5),
              child: pw.Text("Prepared by"),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Text("Checked by"),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 5, bottom: 5),
              child: pw.Text("Authorised Signature"),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _th(String t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

  static pw.Widget _td(String t) {
    return pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(t));
  }

  static pw.Widget _totalRow(String l, double v, {bool isBold = false}) {
    final style = pw.TextStyle(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: 10,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(l, style: style),
          pw.Text(v.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}
