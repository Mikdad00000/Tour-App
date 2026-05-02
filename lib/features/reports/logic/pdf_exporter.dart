import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../expense/domain/expense.dart';

class PdfExporter {
  Future<void> exportTrip({
    required String tripName,
    required List<Expense> expenses,
  }) async {
    final doc = pw.Document();
    final fmt = DateFormat.yMMMd();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text(tripName)),
          pw.Paragraph(text: 'Generated ${DateTime.now()}'),
          pw.Table.fromTextArray(
            headers: ['Date', 'Type', 'Amount', 'Per-head', 'Note'],
            data: expenses
                .map((e) => [
                      fmt.format(e.createdAt),
                      e.type.wire,
                      e.amount.toStringAsFixed(2),
                      e.perHeadAmount.toStringAsFixed(2),
                      e.note ?? '',
                    ])
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}
