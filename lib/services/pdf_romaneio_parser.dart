import 'package:rota_prime/services/excel_parser_service.dart';

/// Converte PDF de romaneio (texto) em linhas importáveis — ML, Amazon, transportadoras, etc.
/// Novos layouts: detectar título/colunas e acrescentar parser (mesmo fluxo da planilha).
class PdfRomaneioParser {
  List<ParsedRow> parse(String text) {
    final normalized = _normalize(text);
    if (_isProtocoloCarregamento(normalized)) {
      return _parseProtocoloCarregamento(normalized);
    }
    if (_isLoggiRelatorioPacotes(normalized)) {
      return _parseRelatorioEntregas(normalized, loggi: true);
    }
    if (_isRelatorioEntregas(normalized)) {
      return _parseRelatorioEntregas(normalized);
    }
    if (_looksLikeProtocoloEntregaRows(normalized)) {
      return _parseProtocoloCarregamento(normalized);
    }
    final lower = normalized.toLowerCase();
    if (lower.contains('magalog') ||
        lower.contains('loggi') ||
        lower.contains('ics delivery') ||
        lower.contains('icsdelivery')) {
      throw FormatException(
        'PDF ${lower.contains('magalog') ? 'Magalog' : lower.contains('loggi') ? 'Loggi' : 'ICS Delivery'} '
        'reconhecido, mas o layout ainda não está mapeado. '
        'Envie uma amostra pelo chat ou importe .xlsx/.csv enquanto ajustamos o parser.',
      );
    }
    throw FormatException(
      'PDF não reconhecido como romaneio ROTA PRIME. '
      'Formatos suportados: "Protocolo de Carregamento" (lista com CEP/endereço) '
      'ou "Relatório de Controle de Entregas e Pacotes". '
      'Se for outro layout, salve como .xlsx/.csv.',
    );
  }

  /// Nº entrega Magalog — 9 dígitos prefixo 30x no início da linha/bloco (NF pode colar depois).
  static final _protocolEntregaAnchor = RegExp(r'(?:^|\s)(30[0-9]{7})');

  static Iterable<int> _protocolEntregaStarts(String body) sync* {
    for (final m in _protocolEntregaAnchor.allMatches(body)) {
      final id = m.group(1)!;
      yield m.start + m.group(0)!.length - id.length;
    }
  }

  /// Blocos de entrega + CEP (sem título de protocolo no PDF).
  static bool _looksLikeProtocoloEntregaRows(String t) {
    return _protocolEntregaAnchor.allMatches(t).length >= 3;
  }

  static String _normalize(String text) {
    var t = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    t = t.replaceAll(RegExp(r'--\s*\d+\s+of\s+\d+\s*--', caseSensitive: false), '\n');
    t = t.replaceAll(RegExp(r'\uFFFD'), '');
    return t;
  }

  static bool _isProtocoloCarregamento(String t) {
    final lower = t.toLowerCase();
    return lower.contains('protocolo de carregamento') &&
        (lower.contains('nº entrega') ||
            lower.contains('no entrega') ||
            lower.contains('n entrega'));
  }

  /// Loggi — “Relatório de Controle de Pacotes” (ID Pacote + Prazo com hora).
  static bool _isLoggiRelatorioPacotes(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('protocolo de carregamento')) return false;
    return lower.contains('relat') &&
        lower.contains('controle de pacotes') &&
        (lower.contains('id pacote') || lower.contains('id do pacote'));
  }

  static bool _isRelatorioEntregas(String t) {
    final lower = t.toLowerCase();
    return lower.contains('relat') &&
        lower.contains('controle de entregas') &&
        lower.contains('pacotes');
  }

  /// Magalog — “Protocolo de Carregamento” (Nº entrega, CEP, endereço, bairro, cidade/UF).
  List<ParsedRow> _parseProtocoloCarregamento(String text) {
    var body = text;
    body = body.replaceFirst(
      RegExp(r'Protocolo de Carregamento[\s\S]*?Cidade/UF\s*', caseSensitive: false),
      '',
    );
    body = body.replaceFirst(
      RegExp(r'Ass\.\s*Motorista[\s\S]*$', caseSensitive: false),
      '',
    );
    body = body.replaceAll('\n', ' ');
    body = body.replaceAll(RegExp(r'\s+'), ' ').trim();

    final starts = <int>[];
    starts.addAll(_protocolEntregaStarts(body));
    final rows = <ParsedRow>[];
    for (var s = 0; s < starts.length; s++) {
      final end = s + 1 < starts.length ? starts[s + 1] : body.length;
      final row = _parseProtocoloRow(body.substring(starts[s], end).trim());
      if (row != null) rows.add(row);
    }
    if (rows.isEmpty) {
      throw const FormatException('Nenhuma entrega encontrada no PDF (Protocolo de Carregamento).');
    }
    if (rows.length == 1 && body.length < 800) {
      throw FormatException(
        'Magalog/Protocolo reconhecido, mas o PDF só liberou 1 entrega como texto '
        '(possível scan/imagem — a tabela não veio selecionável). '
        'Peça PDF com texto ou exporte .xlsx/.csv.',
      );
    }
    return rows;
  }

  ParsedRow? _parseProtocoloRow(String block) {
    if (block.length < 20 || !RegExp(r'^\d{9}').hasMatch(block)) return null;

    final entrega = block.substring(0, 9);
    var rest = block.substring(9).trim();

    final cepMatch = _cepBeforeStreet(rest);
    if (cepMatch == null) return null;

    final cep = cepMatch.group(1)!;
    final beforeCep = rest.substring(0, cepMatch.start).trim();
    final afterCep = rest.substring(cepMatch.end).trim();

    var nf = '';
    var pedido = '';
    var destinatario = beforeCep;

    final gluedHead = RegExp(r'^(\d+\/\d{1,4})(\d{6,15})(.*)$').firstMatch(beforeCep);
    if (gluedHead != null) {
      nf = gluedHead.group(1)!;
      pedido = gluedHead.group(2)!;
      destinatario = gluedHead.group(3)!.trim();
    } else {
      var work = beforeCep;
      final nfMatch = RegExp(r'^(\d+\/\d+)\s*').firstMatch(work);
      if (nfMatch != null) {
        nf = nfMatch.group(1)!;
        work = work.substring(nfMatch.end).trim();
      }
      final pedidoMatch = RegExp(r'^(\d{6,})\s*').firstMatch(work);
      if (pedidoMatch != null) {
        pedido = pedidoMatch.group(1)!;
        destinatario = work.substring(pedidoMatch.end).trim();
      } else {
        destinatario = work;
      }
    }

    var city = '';
    var addressPart = afterCep;
    final slash = afterCep.lastIndexOf('/');
    if (slash > 0 && slash < afterCep.length - 2) {
      final uf = afterCep.substring(slash + 1).trim();
      if (RegExp(r'^[A-Z]{2}$').hasMatch(uf)) {
        final beforeSlash = afterCep.substring(0, slash).trim();
        final words = beforeSlash.split(RegExp(r'\s+'));
        if (words.length >= 2) {
          final cityName = words.sublist(words.length - 2).join(' ');
          city = '$cityName/$uf';
          addressPart = words.sublist(0, words.length - 2).join(' ');
        } else if (words.length == 1) {
          city = '${words.single}/$uf';
          addressPart = '';
        }
      }
    }

    final bairro = _trailingUpperBairro(addressPart);
    var endereco = addressPart;
    if (bairro.isNotEmpty && endereco.endsWith(bairro)) {
      endereco = endereco.substring(0, endereco.length - bairro.length).trim();
    }
    if (endereco.isEmpty && addressPart.isNotEmpty) {
      endereco = addressPart;
    }
    if (endereco.isNotEmpty &&
        !RegExp(r'^(RUA|R\.|AV\.|AVENIDA|ESTRADA|TRAV)', caseSensitive: false)
            .hasMatch(endereco)) {
      endereco = 'RUA $endereco';
    }
    if (endereco.isEmpty) {
      endereco = 'CEP $cep ${city.isNotEmpty ? city : ''}'.trim();
    }

    final tracking = entrega;
    final cells = <String, String>{
      'Transportadora': 'Magalog',
      'Nº Entrega': entrega,
      'NF/Série': nf,
      'Nº Pedido': pedido,
      'Destinatário': destinatario,
      'CEP': cep,
      'Endereço': endereco,
      'Bairro': bairro,
      'Cidade/UF': city,
      'SPX TN': tracking,
    };

    return ParsedRow(
      cells: cells,
      rawLine: '$destinatario — $endereco, $bairro — $city — CEP $cep',
    );
  }

  static RegExpMatch? _cepBeforeStreet(String rest) {
    final tagged = RegExp(
      r'\s(\d{8})\s+(?:RUA|R\.|AV\.|AVENIDA|AV |Estrada|Travessa|R )',
      caseSensitive: false,
    ).firstMatch(' $rest ');
    if (tagged != null) return tagged;
    final br = RegExp(r'\b(2[0-9]{7})\b').allMatches(rest).toList();
    if (br.isNotEmpty) return br.last;
    return RegExp(r'\b(\d{8})\b').firstMatch(rest);
  }

  static String _trailingUpperBairro(String addressPart) {
    final tokens = addressPart.split(RegExp(r'\s+'));
    final tail = <String>[];
    const skipBairroTokens = {'CASA', 'APTO', 'APT', 'NULL', 'BLOCO', 'BL', 'SN', 'S/N'};
    for (var i = tokens.length - 1; i >= 0; i--) {
      final tok = tokens[i];
      if (tok.length < 2) break;
      if (skipBairroTokens.contains(tok)) break;
      if (RegExp(r'^[A-Z0-9][A-Z0-9\-]*$').hasMatch(tok) && tok == tok.toUpperCase()) {
        tail.insert(0, tok);
      } else {
        break;
      }
    }
    return tail.join(' ');
  }

  /// ID Pacote Loggi (8–9 dígitos, 564–566…) + prazo com hora — ignora códigos de barras longos.
  static final _loggiRowAnchor = RegExp(
    r'(?:^|\s)(56[4-6][0-9]{5,7})\s+(\d{2}/\d{2}/\d{4}\s+\d{2}:\d{2})(?=\s)',
  );

  /// Relatório multi-linha — endereço completo + ID pacote (+ Prazo na Loggi).
  List<ParsedRow> _parseRelatorioEntregas(String text, {bool loggi = false}) {
    var body = text;
    body = body.replaceFirst(
      RegExp(
        loggi
            ? r'Relat[\s\S]*?(?:Status do\s*Pacote|Status)\s*'
            : r'Relat[\s\S]*?Status do\s*Pacote\s*',
        caseSensitive: false,
      ),
      '',
    );
    if (loggi) {
      body = body.replaceAll(
        RegExp(
          r'Destinatário\s+Endereço Completo\s+Código de Barras\s+ID Pacote\s+Prazo\s+Entregador\s+Status',
          caseSensitive: false,
        ),
        ' ',
      );
    }
    body = body.replaceAll('\n', ' ');
    body = body.replaceAll(RegExp(r'\s+'), ' ').trim();

    final anchor = loggi
        ? _loggiRowAnchor
        : RegExp(r'(?<![\d/])(56[3-6][0-9]{5,7})\s+(\d{2}/\d{2}/\d{4})(?!\d)');
    final matches = anchor.allMatches(body).toList();
    if (matches.isEmpty) {
      throw FormatException(
        loggi
            ? 'Nenhuma linha Loggi (ID Pacote + Prazo com hora) no PDF.'
            : 'Nenhuma linha de pacote (ID + prazo) no PDF de entregas.',
      );
    }

    final rows = <ParsedRow>[];
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final pkgId = m.group(1)!;
      final prazo = m.group(2)!;
      final chunkStart = i == 0 ? 0 : matches[i - 1].end;
      final chunk = body.substring(chunkStart, m.start).trim();

      var row = _parseRelatorioChunk(chunk, pkgId, prazo: prazo, loggi: loggi);
      row ??= loggi ? _loggiFallbackRow(chunk, pkgId, prazo) : null;
      if (row != null) rows.add(row);
    }

    if (rows.isEmpty) {
      throw const FormatException('Nenhuma entrega válida no relatório PDF.');
    }
    return _dedupeRelatorioRows(rows);
  }

  ParsedRow? _loggiFallbackRow(String chunk, String packageId, String prazo) {
    var c = chunk.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (c.isEmpty) return null;
    c = c.replaceAll(
      RegExp(r'4126091113705107047855022|0031276331816986800', caseSensitive: false),
      ' ',
    );
    final cep = RegExp(r'\b(\d{8})\b').firstMatch(c)?.group(1) ?? '';
    return ParsedRow(
      cells: {
        'Transportadora': 'Loggi',
        'Endereço Completo': c,
        'Destination Address': c,
        'ID do Pacote': packageId,
        'ID Pacote': packageId,
        'ID da Entrega': packageId,
        'Package ID': packageId,
        'Prazo': prazo,
        'SPX TN': packageId,
        if (cep.isNotEmpty) 'CEP': cep,
        'City': 'Belford Roxo/RJ',
      },
      rawLine: c.length > 120 ? '${c.substring(0, 120)}…' : c,
    );
  }

  List<ParsedRow> _dedupeRelatorioRows(List<ParsedRow> rows) {
    final seen = <String>{};
    final out = <ParsedRow>[];
    for (final row in rows) {
      final id = (row.cells['ID do Pacote'] ??
              row.cells['ID Pacote'] ??
              row.cells['Package ID'] ??
              '')
          .trim();
      final key = id.isNotEmpty
          ? 'id:$id'
          : '${row.cells['CEP']}|${row.cells['Endereço Completo']}'.toLowerCase();
      if (key.isEmpty || seen.add(key)) {
        out.add(row);
      }
    }
    return out;
  }

  ParsedRow? _parseRelatorioChunk(
    String chunk,
    String packageId, {
    String prazo = '',
    bool loggi = false,
  }) {
    var c = chunk.replaceAll('\n', ' ');
    c = c.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (c.isEmpty) return null;

    c = c.replaceAll(
      RegExp(
        r'Nome do Destinatário|Destinatário|Endereço Completo|Código de Barras|ID do Pacote|ID Pacote|Prazo|Entregador|Status do Pacote|Status|Retirado|Nascimento',
        caseSensitive: false,
      ),
      ' ',
    );
    c = c.replaceAll(RegExp(r'Ana Beatriz In[aá]cio(\s+Nascimento)?', caseSensitive: false), ' ');
    c = c.replaceAll(RegExp(r'\s+'), ' ').trim();

    final addrPattern = RegExp(
      r'((?:Rua|RUA|Estrada|Travessa|AVENIDA|Avenida|Boulevard|Avenida|Sao Jose|ESTRADA)[\s\S]{10,}?\d{8}[\s\S]{0,50}?Brasil[\s\S]{0,160}?)(?=\s+[A-Z0-9]{6,}|\s+56[3-6]|\s+\d{9}\s|$)',
      caseSensitive: false,
    );
    var addrMatches = addrPattern.allMatches(c).toList();
    if (addrMatches.isEmpty && loggi) {
      addrMatches = RegExp(
        r'([A-Za-zÀ-ú][\s\S]{15,}?\d{8}[\s\S]{0,50}?Brasil[\s\S]{0,120}?)',
        caseSensitive: false,
      ).allMatches(c).toList();
    }
    if (addrMatches.isEmpty) return null;

    final addrMatch = addrMatches.last;
    final address = addrMatch.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
    var name = c.substring(0, addrMatch.start).trim();
    name = name.replaceAll(RegExp(r'[\(\)]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.length > 80) {
      name = name.split(' ').take(6).join(' ');
    }

    final cepMatch = RegExp(r'\b(\d{8})\b').firstMatch(address);
    final cep = cepMatch?.group(1) ?? '';

    var city = 'Belford Roxo/RJ';
    final cityMatch = RegExp(r',\s*([^,]+)\s*-\s*RJ\s*,', caseSensitive: false).firstMatch(address);
    if (cityMatch != null) {
      city = '${cityMatch.group(1)!.trim()}/RJ';
    }

    final tail = c.substring(addrMatch.end).trim();
    final barcodeMatch = RegExp(r'^([A-Z0-9_]{8,})').firstMatch(tail);
    final barcode = barcodeMatch?.group(1) ?? '';

    final cells = <String, String>{
      if (loggi) 'Transportadora': 'Loggi',
      'Nome do Destinatário': name,
      'Destinatário': name,
      'Endereço Completo': address,
      'Destination Address': address,
      if (barcode.isNotEmpty) 'Código de Barras': barcode,
      'ID do Pacote': packageId,
      'ID Pacote': packageId,
      'Package ID': packageId,
      'ID da Entrega': packageId,
      if (prazo.isNotEmpty) 'Prazo': prazo,
      'SPX TN': packageId,
      'CEP': cep,
      'Zipcode': cep,
      'City': city,
    };

    return ParsedRow(
      cells: cells,
      rawLine: name.isNotEmpty ? '$name — $address' : address,
    );
  }
}
