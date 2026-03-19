import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

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
      (await rootBundle.load('assets/images/Valampure-logo.jpeg')).buffer.asUint8List(),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (context)  {

          double totalMts = 0;
          for (var i in items) {
            totalMts += (i.boxes * i.mts);
          }


          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [

                _header(company, invoiceNo, headerFont, logoImage),

                _gstSection(company, orderNo, invoiceNo),

                _consigneeSection(buyerName, buyerGST, buyerState, buyerStateCode),

                _itemsTable(items, totalMts),

                _bankAndTotal(bank, subTotal, tax, grandTotal),

                _certificate(),

                _conditions(),

                pw.Spacer(),

                _bottomSign(company),

              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  /// HEADER
  static pw.Widget _header(Map<String, String> c, String invoiceNo, pw.Font headerFont, pw.MemoryImage logoImage) {

    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [

          pw.Container(
            width: 70,
            height: 70,
            child: pw.Center(
              child: pw.Image(
                logoImage,
                fit: pw.BoxFit.contain,
              ),
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
                    fontSize: 30,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.Text(
                  "Manufacturers And Suppliers Of Imported Rubber Elastic Tapes",
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.Text(
                  c['address1'] ?? "",
                  style: pw.TextStyle(fontSize: 10),
                ),

                pw.Text(
                  c['address2'] ?? "",
                  style: pw.TextStyle(fontSize: 10),
                ),
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
                  padding: const pw.EdgeInsets.symmetric(vertical:4),
                  child: pw.Center(
                    child: pw.Text(
                      "TAX INVOICE",
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold
                      ),
                    ),
                  ),
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("S.No."),
                    pw.Text(invoiceNo)
                  ],
                ),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Date"),
                    pw.Text(DateFormat("dd-MM-yyyy").format(DateTime.now()))
                  ],
                ),

              ],
            ),
          )

        ],
      ),
    );
  }

  /// GST + ORDER SECTION
  static pw.Widget _gstSection(
      Map<String, String> company,
      String orderNo,
      String invoiceNo) {

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
                _infoRow("DATE", DateFormat("dd-MM-yyyy").format(DateTime.now())),

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
          border: pw.Border(bottom: pw.BorderSide(width: 1))),
      child: pw.Row(
        children: [

          pw.Expanded(
              child: pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(l))),

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
      String code) {

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
                        fontSize: 9),
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

          pw.Expanded(
            flex: 4,
            child: pw.Center(child: _sealSection()),
          ),

        ],
      ),
    );
  }

  static pw.Widget _sealSection() {

    return pw.Container(
      width: 70,
      height: 70,
      decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          border: pw.Border.all()),
      child: pw.Center(
        child: pw.Text(
          "VALAMPURE\nELASTICS",
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7),
        ),
      ),
    );
  }

  /// ITEMS TABLE
  static pw.Widget _itemsTable(List items, double totalMts) {

    const int maxRows = 8;
    int emptyRows = maxRows - items.length;

    List<pw.TableRow> rows = [];

    rows.add(
      pw.TableRow(
        decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide())),
        children: [
          _th("S.No."),
          _th("Description of Goods"),
          _th("HSN Code"),
//          _th("No. & Description of Packages"),
          _th("Box"),
          _th("MTS"),
          _th("Total Qty"),
          _th("Rate"),
          _th("Total Value"),
        ],
      ),
    );

    for (var e in items.asMap().entries) {

      final item = e.value;

      double qty = item.boxes * item.mts;
      double total = qty * item.rate;

      rows.add(
        pw.TableRow(
          children: [
            _td("${e.key + 1}"),
            _td("12 - " + item.description),
            _td("60"),
            _td(item.boxes.toString()),
            _td(item.mts.toString()),
            _td(qty.toString()),
            _td(item.rate.toString()),
            _td(total.toStringAsFixed(2)),
          ],
        ),
      );
    }

    for (int i = 0; i < emptyRows; i++) {
      rows.add(
        pw.TableRow(
          children: List.generate(
              8,
                  (index) => pw.Container(height: 20)),
        ),
      );
    }

    rows.add(
      pw.TableRow(
        decoration:
        pw.BoxDecoration(border: pw.Border(top: pw.BorderSide())),
        children: [
          _td(""),
          _td("TOTAL MTS"),
          _td(""),
          _td(""),
          _td(""),
          _td(totalMts.toString()),
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
        verticalInside: pw.BorderSide(),
      ),
      children: rows,
    );
  }

  /// BANK + TOTAL
  static pw.Widget _bankAndTotal(
      Map<String, String> bank,
      double sub,
      double tax,
      double grand) {

    return pw.Column(
      children: [

        pw.Container(
          height: 100,
          child: pw.Row(
            children: [

              pw.Expanded(
                flex: 6,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                      pw.Text("Bank Name : ${bank['bankName']}"),
                      pw.Text("Ac No : ${bank['accountNo']}"),
                      pw.Text("IFSC Code : ${bank['ifsc']}"),

                    ],
                  ),
                ),
              ),

              pw.Container(width: 1, color: PdfColors.black),

              pw.Expanded(
                flex: 4,
                child: pw.Column(
                  children: [

                    _totalRow("TOTAL", sub),
                    _totalRow("SGST 2.5%", tax / 2),
                    _totalRow("CGST 2.5%", tax / 2),
                    _totalRow("ROUND OFF", 0),
                    _totalRow("GRAND TOTAL", grand),

                  ],
                ),
              ),

            ],
          ),
        ),

        pw.Divider(),

        _amountWords(grand),

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
      "ONE","TWO","THREE","FOUR","FIVE","SIX","SEVEN","EIGHT","NINE","TEN",
      "ELEVEN","TWELVE","THIRTEEN","FOURTEEN","FIFTEEN","SIXTEEN",
      "SEVENTEEN","EIGHTEEN","NINETEEN"
    ];

    final tens = [
      "","","TWENTY","THIRTY","FORTY","FIFTY","SIXTY","SEVENTY","EIGHTY","NINETY"
    ];

    String convert(int n) {

      if (n < 20) return units[n];

      if (n < 100) {
        return tens[n ~/ 10] +
            (n % 10 != 0 ? " ${units[n % 10]}" : "");
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

        pw.Divider(),

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
            "Certified that the particulars given above are true and correct and the amount indicated in this document represents the price actually charged by us.",
            style: pw.TextStyle(fontSize: 8),
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
      child: pw.Text(
        t,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _td(String t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(t),
    );
  }

  static pw.Widget _totalRow(String l, double v) {

    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [

          pw.Text(l),
          pw.Text(v.toStringAsFixed(2)),

        ],
      ),
    );
  }
}