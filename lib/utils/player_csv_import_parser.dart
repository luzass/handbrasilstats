import '../models/player_csv_import_row.dart';
import 'csv_utils.dart';

List<PlayerCsvImportRow> parsePlayerCsvImportRows(String csvContent) {
  final parsedRows = parseCsvRows(csvContent);
  if (parsedRows.isEmpty) {
    return const [];
  }

  final headerMap = <String, int>{};
  for (var index = 0; index < parsedRows.first.length; index++) {
    headerMap[_normalizeHeader(parsedRows.first[index])] = index;
  }

  final hasNameColumn = _firstColumnIndex(headerMap, const [
    'full_name',
    'nome',
    'nome_completo',
  ]);

  if (hasNameColumn == null) {
    throw Exception(
      'O CSV precisa ter a coluna full_name, nome ou nome_completo.',
    );
  }

  final rows = <PlayerCsvImportRow>[];

  for (var rowIndex = 1; rowIndex < parsedRows.length; rowIndex++) {
    final values = parsedRows[rowIndex];
    final fullName = _readCell(
      values,
      headerMap,
      const ['full_name', 'nome', 'nome_completo'],
    );

    if (fullName == null || fullName.isEmpty) {
      continue;
    }

    rows.add(
      PlayerCsvImportRow(
        sourceRowNumber: rowIndex + 1,
        fullName: fullName,
        cpf: _readCell(values, headerMap, const ['cpf']),
        birthDate: _readCell(
          values,
          headerMap,
          const ['birth_date', 'data_nascimento'],
        ),
        heightCm: _parseHeight(
          _readCell(
            values,
            headerMap,
            const ['height_cm', 'altura_cm', 'altura'],
          ),
        ),
        birthCity: _readCell(
          values,
          headerMap,
          const ['birth_city', 'cidade_natal', 'cidade'],
        ),
        dominantHand: _normalizeDominantHand(
          _readCell(
            values,
            headerMap,
            const ['dominant_hand', 'mao_dominante'],
          ),
        ),
        primaryPosition: _normalizePrimaryPosition(
          _readCell(
            values,
            headerMap,
            const ['primary_position', 'posicao_principal', 'posicao'],
          ),
        ),
        titlesText: _readCell(
          values,
          headerMap,
          const ['titles_text', 'titulos', 'titulos_texto'],
        ),
        isActive: _parseBool(
          _readCell(values, headerMap, const ['is_active', 'ativo']),
        ),
      ),
    );
  }

  return rows;
}

int? _firstColumnIndex(
  Map<String, int> headerMap,
  List<String> aliases,
) {
  for (final alias in aliases) {
    final index = headerMap[alias];
    if (index != null) {
      return index;
    }
  }

  return null;
}

String? _readCell(
  List<String> values,
  Map<String, int> headerMap,
  List<String> aliases,
) {
  final index = _firstColumnIndex(headerMap, aliases);
  if (index == null || index >= values.length) {
    return null;
  }

  final value = values[index].trim();
  return value.isEmpty ? null : value;
}

String _normalizeHeader(String value) {
  final base = value
      .trim()
      .toLowerCase()
      .replaceAll('\u00E3', 'a')
      .replaceAll('\u00E1', 'a')
      .replaceAll('\u00E0', 'a')
      .replaceAll('\u00E2', 'a')
      .replaceAll('\u00E4', 'a')
      .replaceAll('\u00E9', 'e')
      .replaceAll('\u00EA', 'e')
      .replaceAll('\u00ED', 'i')
      .replaceAll('\u00F3', 'o')
      .replaceAll('\u00F4', 'o')
      .replaceAll('\u00F5', 'o')
      .replaceAll('\u00FA', 'u')
      .replaceAll('\u00E7', 'c');

  return base
      .replaceAll(' ', '_')
      .replaceAll('-', '_')
      .replaceAll('/', '_');
}

double? _parseHeight(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return double.tryParse(value.replaceAll(',', '.'));
}

bool? _parseBool(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = value.trim().toLowerCase();
  if (const ['true', '1', 'sim', 's', 'yes', 'ativo'].contains(normalized)) {
    return true;
  }
  if (const ['false', '0', 'nao', 'n\u00E3o', 'n', 'no', 'inativo']
      .contains(normalized)) {
    return false;
  }

  return null;
}

String? _normalizeDominantHand(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = _normalizeHeader(value);
  switch (normalized) {
    case 'destro':
    case 'direito':
    case 'direita':
    case 'right':
      return 'destro';
    case 'canhoto':
    case 'esquerdo':
    case 'esquerda':
    case 'left':
      return 'canhoto';
    case 'ambidestro':
    case 'ambi':
    case 'ambidextra':
      return 'ambidestro';
    default:
      return 'nao_informado';
  }
}

String? _normalizePrimaryPosition(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final normalized = _normalizeHeader(value);
  switch (normalized) {
    case 'goleiro':
    case 'gol':
    case 'gk':
      return 'goleiro';
    case 'ponta_esquerda':
    case 'pe':
      return 'ponta_esquerda';
    case 'armador_esquerdo':
    case 'ae':
      return 'armador_esquerdo';
    case 'armador_central':
    case 'central':
    case 'ac':
      return 'armador_central';
    case 'armador_direito':
    case 'ad':
      return 'armador_direito';
    case 'ponta_direita':
    case 'pd':
      return 'ponta_direita';
    case 'pivo':
      return 'pivo';
    default:
      return 'nao_informado';
  }
}
