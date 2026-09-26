import 'package:flutter_test/flutter_test.dart';
import 'package:rota_prime/services/pdf_romaneio_parser.dart';
import 'package:rota_prime/utils/column_matcher.dart';

void main() {
  final parser = PdfRomaneioParser();

  test('Protocolo de Carregamento — extrai CEP e endereço', () {
    const sample = '''
Protocolo de Carregamento
Nº Entrega NF/Série Nº Pedido Destinatário CEP Endereço Bairro Cidade/UF
30555769010053585/171100173208601 RAYSSA SILVA DO NASCIMENTO 26271133 RUA HERCILIA DE JESUS 200 CASA JARDIM PALMARES Nova Iguaçu/RJ
305508110 2049/8 1569070103820085 JOSE CLAUDIO DA CONCEICAO 26271160 RUA MARCIA COSTA 587 JARDIM NOVA ERA Nova Iguaçu/RJ
Ass. Motorista
''';

    final rows = parser.parse(sample);
    expect(rows.length, 2);
    expect(pickCell(rows.first.cells, zipAliases), '26271133');
    expect(
      pickCell(rows.first.cells, addressAliases),
      contains('HERCILIA DE JESUS'),
    );
    expect(rows.first.cells['SPX TN'], '305557690');
    expect(pickCell(rows.first.cells, spxAliases), '305557690');
  });

  test('Magalog — Nº entrega 307… (Belford Roxo)', () {
    const sample = '''
Protocolo de Carregamento
Nº Entrega NF/Série Nº Pedido Destinatário CEP Endereço Bairro Cidade/UF
307549232 17814710/10 100226229401 MARIA SILVA 26112055 RUA SAO JOSE 100 CASA CENTRO Belford Roxo/RJ
307549233 17814710/11 100226229401402 JOAO SILVA 26112056 RUA SAO JOSE 101 CASA CENTRO Belford Roxo/RJ
Ass. Motorista
''';

    final rows = parser.parse(sample);
    expect(rows.length, 2);
    expect(rows.first.cells['Nº Entrega'], '307549232');
    expect(pickCell(rows.first.cells, zipAliases), '26112055');
    expect(rows.first.cells['Transportadora'], 'Magalog');
  });

  test('Loggi — Controle de Pacotes, ID + prazo com hora', () {
    const sample = '''
Relatório de Controle de Pacotes - Revisão Gramatical
Destinatário Endereço Completo Código de Barras ID Pacote Prazo Entregador Status
Larissa Cosmo Rua Apodi, 15 - São José, Belford Roxo - RJ, 26187300, Brasil - Casa
LG3EDI36YCIZY7R6HBP3
565481711
23/09/2026 22:00
Ana Beatriz Inácio Nascimento
Retirado
''';

    final rows = parser.parse(sample);
    expect(rows.length, greaterThanOrEqualTo(1));
    expect(rows.first.cells['Transportadora'], 'Loggi');
    expect(rows.first.cells['ID do Pacote'], '565481711');
    expect(rows.first.cells['Prazo'], '23/09/2026 22:00');
    expect(rows.first.cells['ID da Entrega'], '565481711');
  });

  test('Relatório de entregas — ID pacote e endereço com CEP', () {
    const sample = '''
Relatório de Controle de Entregas e Pacotes
Geilson Silva Oliveira de Alme
Rua Apodi, 15 - São José, Belford Roxo - RJ, 26187300, Brasil - Quadra 47
47977286574
563608526
14/09/2026
Retirado
Renata Santos Lima
Rua Vinte e Cinco de Agosto, 6 - Lote XV, Belford Roxo - RJ, 26183290, Brasil -
LG3COM4Q2UKXYJ3XZRYV
563513471
15/09/2026
Retirado
''';

    final rows = parser.parse(sample);
    expect(rows.length, greaterThanOrEqualTo(2));
    expect(pickCell(rows.first.cells, zipAliases), '26187300');
    expect(pickCell(rows.first.cells, addressAliases), contains('Apodi'));
    expect(pickCell(rows.last.cells, spxAliases), isNotEmpty);
  });
}
