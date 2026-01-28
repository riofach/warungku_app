import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import 'package:warungku_app/core/utils/formatters.dart';
import 'package:warungku_app/features/pos/data/models/transaction_model.dart';
import 'package:warungku_app/features/reports/data/models/report_summary_model.dart';
import 'package:warungku_app/features/reports/data/models/top_item_model.dart';

class PdfService {
  /// Membuat dan menampilkan preview PDF laporan
  Future<void> generateReport({
    required ReportSummary summary,
    required List<Transaction> transactions,
    required List<TopItem> topItems,
    required String period,
  }) async {
    final pdf = pw.Document();
    
    // Load Logo
    final logoImage = await imageFromAssetBundle('assets/images/logo-warung.png');
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: fontRegular,
            bold: fontBold,
          ),
        ),
        header: (context) => _buildHeader(context, logoImage, period),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(summary),
          pw.SizedBox(height: 20),
          _buildTopItemsTable(topItems),
          pw.SizedBox(height: 20),
          _buildTransactionTable(transactions),
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
    String period,
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
                  'Laporan Penjualan',
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
          'Periode: $period',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildSummarySection(ReportSummary summary) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard('Total Omset', formatRupiah(summary.totalRevenue)),
        _buildSummaryCard('Total Profit', formatRupiah(summary.totalProfit)),
        _buildSummaryCard('Total Transaksi', '${summary.transactionCount}'),
      ],
    );
  }

  pw.Widget _buildSummaryCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      width: 150,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTopItemsTable(List<TopItem> items) {
    if (items.isEmpty) return pw.Container();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Barang Terlaris',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Rank', 'Barang', 'Terjual', 'Omset'],
          data: items.asMap().entries.map((entry) {
            final index = entry.key + 1;
            final item = entry.value;
            return [
              '#$index',
              item.itemName,
              '${item.totalQuantity}',
              formatRupiah(item.totalRevenue),
            ];
          }).toList(),
          border: null,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5)),
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(8),
          headerPadding: const pw.EdgeInsets.all(8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionTable(List<Transaction> transactions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daftar Transaksi',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['Waktu', 'Kode', 'Metode', 'Total'],
          data: transactions.map((t) {
            return [
              DateFormat('dd MMM yyyy, HH:mm').format(t.createdAt),
              t.code,
              t.paymentMethod.toUpperCase(),
              formatRupiah(t.total),
            ];
          }).toList(),
          border: null,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: .5)),
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellPadding: const pw.EdgeInsets.all(8),
          headerPadding: const pw.EdgeInsets.all(8),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
        ),
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
}
