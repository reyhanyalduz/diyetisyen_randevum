import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/diet_plan.dart';

class PdfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Varsayılan yazı boyutları
  static const double defaultTitleSize = 24.0;
  static const double defaultSubtitleSize = 16.0;
  static const double defaultTextSize = 12.0;

  Future<void> generateDietPlanPdf(
    DietPlan dietPlan, {
    double titleSize = defaultTitleSize,
    double subtitleSize = defaultSubtitleSize,
    double textSize = defaultTextSize,
  }) async {
    final pdf = pw.Document();

    final createdAt = dietPlan.createdAt.toDate();

    // Danışan bilgilerini al
    final clientDoc =
        await _firestore.collection('clients').doc(dietPlan.clientId).get();
    String clientName = 'Danışan';
    if (clientDoc.exists) {
      clientName = clientDoc.data()?['name'] ?? 'Danışan';
    }

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: pw.Font.ttf(
                await rootBundle.load("assets/fonts/OpenSans-Regular.ttf")),
            bold: pw.Font.ttf(
                await rootBundle.load("assets/fonts/OpenSans-Bold.ttf")),
          ),
        ),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              dietPlan.title,
              style: pw.TextStyle(
                fontSize: titleSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Tarih: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
            style: pw.TextStyle(fontSize: textSize),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Danışan: $clientName',
            style: pw.TextStyle(fontSize: textSize),
          ),
          pw.SizedBox(height: 20),
          _buildMealSection(
              'Kahvaltı', dietPlan.breakfast, dietPlan.breakfastTime,
              subtitleSize: subtitleSize, textSize: textSize),
          pw.SizedBox(height: 15),
          _buildMealSection('Öğle Yemeği', dietPlan.lunch, dietPlan.lunchTime,
              subtitleSize: subtitleSize, textSize: textSize),
          pw.SizedBox(height: 15),
          _buildMealSection('Ara Öğün', dietPlan.snack, dietPlan.snackTime,
              subtitleSize: subtitleSize, textSize: textSize),
          pw.SizedBox(height: 15),
          _buildMealSection(
              'Akşam Yemeği', dietPlan.dinner, dietPlan.dinnerTime,
              subtitleSize: subtitleSize, textSize: textSize),
          if (dietPlan.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Notlar:',
              style: pw.TextStyle(
                fontSize: subtitleSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              dietPlan.notes,
              style: pw.TextStyle(fontSize: textSize),
            ),
          ],
        ],
      ),
    );

    // PDF'i kaydet ve aç
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/diyet_plani.pdf');
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  pw.Widget _buildMealSection(
    String title,
    String content,
    String time, {
    double subtitleSize = defaultSubtitleSize,
    double textSize = defaultTextSize,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: subtitleSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Saat: $time',
          style: pw.TextStyle(fontSize: textSize),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          content,
          style: pw.TextStyle(fontSize: textSize),
        ),
      ],
    );
  }
}
