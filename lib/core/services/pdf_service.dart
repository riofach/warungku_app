import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfService {
  /// Membuat dan menampilkan preview PDF laporan
  Future<void> generateAndShowReport({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    String? dateRange,
  }) async {
    final pdf = pw.Document();
    
    // Load Logo
    final logoImage = await imageFromAssetBundle('assets/images/logo-warung.png');
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    // Buat data dummy yang banyak jika data kosong (untuk test pagination)
    final displayData = data.isEmpty ? _generateDummyData(100) : data;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
        ),
        header: (context) => _buildHeader(context, logoImage, title, dateRange),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildTable(headers, displayData),
        ],
      ),
    );

    // Tampilkan preview / share sheet
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_WarungKu_${DateFormat('yyyyMMdd').format(DateTime.now())}',
    );
  }

  pw.Widget _buildHeader(
    pw.Context context, 
    pw.ImageProvider logo, 
    String title,
    String? dateRange,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'WARUNGKU DIGITAL',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Laporan Resmi',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Container(
              height: 50,
              width: 50,
              child: pw.Image(logo),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 10),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (dateRange != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Periode: $dateRange',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey,
        ),
      ),
    );
  }

  pw.Widget _buildTable(List<String> headers, List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: null,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.blue600,
      ),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey300,
            width: .5,
          ),
        ),
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      headerPadding: const pw.EdgeInsets.all(8),
      oddRowDecoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
      ),
    );
  }

  List<List<String>> _generateDummyData(int count) {
    return List.generate(count, (index) {
      return [
        '${index + 1}',
        'INV-202601${index.toString().padLeft(2, '0')}',
        DateFormat('dd MMM yyyy').format(DateTime.now()),
        'Customer ${index + 1}',
        'Rp ${(index + 1) * 15000}',
        index % 2 == 0 ? 'Lunas' : 'Pending',
      ];
    });
  }
}
