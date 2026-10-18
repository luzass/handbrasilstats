import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('team report summary widgets fit inside a paginated PDF', () async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (_) => [
          pw.Row(
            children: [
              for (var i = 0; i < 4; i++)
                pw.Expanded(
                  child: pw.Container(
                    height: 52,
                    margin: const pw.EdgeInsets.only(right: 7),
                    padding: const pw.EdgeInsets.all(9),
                    child: pw.Text('Resumo'),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            height: 330,
            child: pw.SvgImage(
              svg:
                  '''<svg xmlns="http://www.w3.org/2000/svg" width="100" height="80" viewBox="0 0 100 80"><rect width="100" height="80" fill="#07152D"/><text x="50" y="40" fill="#FFFFFF" text-anchor="middle">Mapa</text></svg>''',
              fit: pw.BoxFit.contain,
            ),
          ),
        ],
      ),
    );

    expect(await pdf.save(), isNotEmpty);
  });
}
