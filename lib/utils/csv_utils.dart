import 'dart:convert';
import 'dart:typed_data';

String decodeCsvBytes(Uint8List bytes) {
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return latin1.decode(bytes);
  }
}

List<List<String>> parseCsvRows(String content) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final nonEmptyLines = normalized
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  if (nonEmptyLines.isEmpty) {
    return const [];
  }

  final headerLine = nonEmptyLines.first;
  final semicolonCount = ';'.allMatches(headerLine).length;
  final commaCount = ','.allMatches(headerLine).length;
  final delimiter = semicolonCount > commaCount ? ';' : ',';

  return _parseWithDelimiter(normalized, delimiter)
      .where((row) => row.any((cell) => cell.trim().isNotEmpty))
      .map((row) {
        if (row.isEmpty) return row;
        final firstCell = row.first.replaceFirst('\ufeff', '');
        return [firstCell, ...row.skip(1)];
      }).toList();
}

List<List<String>> _parseWithDelimiter(String content, String delimiter) {
  final rows = <List<String>>[];
  final currentRow = <String>[];
  final currentField = StringBuffer();
  var isInsideQuotes = false;

  for (var index = 0; index < content.length; index++) {
    final char = content[index];
    final nextChar = index + 1 < content.length ? content[index + 1] : null;

    if (char == '"') {
      if (isInsideQuotes && nextChar == '"') {
        currentField.write('"');
        index++;
      } else {
        isInsideQuotes = !isInsideQuotes;
      }
      continue;
    }

    if (!isInsideQuotes && char == delimiter) {
      currentRow.add(currentField.toString().trim());
      currentField.clear();
      continue;
    }

    if (!isInsideQuotes && char == '\n') {
      currentRow.add(currentField.toString().trim());
      rows.add(List<String>.from(currentRow));
      currentRow.clear();
      currentField.clear();
      continue;
    }

    currentField.write(char);
  }

  if (currentField.isNotEmpty || currentRow.isNotEmpty) {
    currentRow.add(currentField.toString().trim());
    rows.add(List<String>.from(currentRow));
  }

  return rows;
}
