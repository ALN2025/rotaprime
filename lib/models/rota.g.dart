// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rota.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetRotaRecordCollection on Isar {
  IsarCollection<RotaRecord> get rotaRecords => this.collection();
}

const RotaRecordSchema = CollectionSchema(
  name: r'RotaRecord',
  id: -699632468332785885,
  properties: {
    r'arquivoPlanilhaImportada': PropertySchema(
      id: 0,
      name: r'arquivoPlanilhaImportada',
      type: IsarType.string,
    ),
    r'criadaEm': PropertySchema(
      id: 1,
      name: r'criadaEm',
      type: IsarType.dateTime,
    ),
    r'distanciaKm': PropertySchema(
      id: 2,
      name: r'distanciaKm',
      type: IsarType.double,
    ),
    r'duracaoMinutos': PropertySchema(
      id: 3,
      name: r'duracaoMinutos',
      type: IsarType.long,
    ),
    r'finalizadaEm': PropertySchema(
      id: 4,
      name: r'finalizadaEm',
      type: IsarType.dateTime,
    ),
    r'kmFinal': PropertySchema(id: 5, name: r'kmFinal', type: IsarType.double),
    r'kmInicial': PropertySchema(
      id: 6,
      name: r'kmInicial',
      type: IsarType.double,
    ),
    r'origemLatitude': PropertySchema(
      id: 7,
      name: r'origemLatitude',
      type: IsarType.double,
    ),
    r'origemLongitude': PropertySchema(
      id: 8,
      name: r'origemLongitude',
      type: IsarType.double,
    ),
    r'otimizada': PropertySchema(
      id: 9,
      name: r'otimizada',
      type: IsarType.bool,
    ),
    r'ownerEmail': PropertySchema(
      id: 10,
      name: r'ownerEmail',
      type: IsarType.string,
    ),
    r'pacotesImportados': PropertySchema(
      id: 11,
      name: r'pacotesImportados',
      type: IsarType.long,
    ),
    r'paradasImportadas': PropertySchema(
      id: 12,
      name: r'paradasImportadas',
      type: IsarType.long,
    ),
    r'romaneioLayout': PropertySchema(
      id: 13,
      name: r'romaneioLayout',
      type: IsarType.byte,
      enumMap: _RotaRecordromaneioLayoutEnumValueMap,
    ),
    r'rotaGeometriaJson': PropertySchema(
      id: 14,
      name: r'rotaGeometriaJson',
      type: IsarType.string,
    ),
    r'status': PropertySchema(
      id: 15,
      name: r'status',
      type: IsarType.byte,
      enumMap: _RotaRecordstatusEnumValueMap,
    ),
    r'titulo': PropertySchema(id: 16, name: r'titulo', type: IsarType.string),
    r'valorPago': PropertySchema(
      id: 17,
      name: r'valorPago',
      type: IsarType.double,
    ),
  },

  estimateSize: _rotaRecordEstimateSize,
  serialize: _rotaRecordSerialize,
  deserialize: _rotaRecordDeserialize,
  deserializeProp: _rotaRecordDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _rotaRecordGetId,
  getLinks: _rotaRecordGetLinks,
  attach: _rotaRecordAttach,
  version: '3.3.2',
);

int _rotaRecordEstimateSize(
  RotaRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.arquivoPlanilhaImportada;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.ownerEmail.length * 3;
  {
    final value = object.rotaGeometriaJson;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.titulo.length * 3;
  return bytesCount;
}

void _rotaRecordSerialize(
  RotaRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.arquivoPlanilhaImportada);
  writer.writeDateTime(offsets[1], object.criadaEm);
  writer.writeDouble(offsets[2], object.distanciaKm);
  writer.writeLong(offsets[3], object.duracaoMinutos);
  writer.writeDateTime(offsets[4], object.finalizadaEm);
  writer.writeDouble(offsets[5], object.kmFinal);
  writer.writeDouble(offsets[6], object.kmInicial);
  writer.writeDouble(offsets[7], object.origemLatitude);
  writer.writeDouble(offsets[8], object.origemLongitude);
  writer.writeBool(offsets[9], object.otimizada);
  writer.writeString(offsets[10], object.ownerEmail);
  writer.writeLong(offsets[11], object.pacotesImportados);
  writer.writeLong(offsets[12], object.paradasImportadas);
  writer.writeByte(offsets[13], object.romaneioLayout.index);
  writer.writeString(offsets[14], object.rotaGeometriaJson);
  writer.writeByte(offsets[15], object.status.index);
  writer.writeString(offsets[16], object.titulo);
  writer.writeDouble(offsets[17], object.valorPago);
}

RotaRecord _rotaRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RotaRecord();
  object.arquivoPlanilhaImportada = reader.readStringOrNull(offsets[0]);
  object.criadaEm = reader.readDateTime(offsets[1]);
  object.distanciaKm = reader.readDouble(offsets[2]);
  object.duracaoMinutos = reader.readLong(offsets[3]);
  object.finalizadaEm = reader.readDateTimeOrNull(offsets[4]);
  object.id = id;
  object.kmFinal = reader.readDoubleOrNull(offsets[5]);
  object.kmInicial = reader.readDouble(offsets[6]);
  object.origemLatitude = reader.readDoubleOrNull(offsets[7]);
  object.origemLongitude = reader.readDoubleOrNull(offsets[8]);
  object.otimizada = reader.readBool(offsets[9]);
  object.ownerEmail = reader.readString(offsets[10]);
  object.pacotesImportados = reader.readLong(offsets[11]);
  object.paradasImportadas = reader.readLong(offsets[12]);
  object.romaneioLayout =
      _RotaRecordromaneioLayoutValueEnumMap[reader.readByteOrNull(
        offsets[13],
      )] ??
      ImportRomaneioLayout.padrao;
  object.rotaGeometriaJson = reader.readStringOrNull(offsets[14]);
  object.status =
      _RotaRecordstatusValueEnumMap[reader.readByteOrNull(offsets[15])] ??
      RotaStatus.rascunho;
  object.titulo = reader.readString(offsets[16]);
  object.valorPago = reader.readDouble(offsets[17]);
  return object;
}

P _rotaRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (_RotaRecordromaneioLayoutValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ImportRomaneioLayout.padrao)
          as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (_RotaRecordstatusValueEnumMap[reader.readByteOrNull(offset)] ??
              RotaStatus.rascunho)
          as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RotaRecordromaneioLayoutEnumValueMap = {
  'padrao': 0,
  'shopeeOrdemPacote': 1,
  'pdfRelatorioRj': 2,
  'pdfProtocoloEntrega': 3,
};
const _RotaRecordromaneioLayoutValueEnumMap = {
  0: ImportRomaneioLayout.padrao,
  1: ImportRomaneioLayout.shopeeOrdemPacote,
  2: ImportRomaneioLayout.pdfRelatorioRj,
  3: ImportRomaneioLayout.pdfProtocoloEntrega,
};
const _RotaRecordstatusEnumValueMap = {
  'rascunho': 0,
  'ativa': 1,
  'finalizada': 2,
};
const _RotaRecordstatusValueEnumMap = {
  0: RotaStatus.rascunho,
  1: RotaStatus.ativa,
  2: RotaStatus.finalizada,
};

Id _rotaRecordGetId(RotaRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _rotaRecordGetLinks(RotaRecord object) {
  return [];
}

void _rotaRecordAttach(IsarCollection<dynamic> col, Id id, RotaRecord object) {
  object.id = id;
}

extension RotaRecordQueryWhereSort
    on QueryBuilder<RotaRecord, RotaRecord, QWhere> {
  QueryBuilder<RotaRecord, RotaRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension RotaRecordQueryWhere
    on QueryBuilder<RotaRecord, RotaRecord, QWhereClause> {
  QueryBuilder<RotaRecord, RotaRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension RotaRecordQueryFilter
    on QueryBuilder<RotaRecord, RotaRecord, QFilterCondition> {
  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'arquivoPlanilhaImportada'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'arquivoPlanilhaImportada'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'arquivoPlanilhaImportada',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'arquivoPlanilhaImportada',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'arquivoPlanilhaImportada',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'arquivoPlanilhaImportada',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'arquivoPlanilhaImportada',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'arquivoPlanilhaImportada',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'arquivoPlanilhaImportada',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'arquivoPlanilhaImportada',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'arquivoPlanilhaImportada',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  arquivoPlanilhaImportadaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'arquivoPlanilhaImportada',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> criadaEmEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'criadaEm', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  criadaEmGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'criadaEm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> criadaEmLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'criadaEm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> criadaEmBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'criadaEm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  distanciaKmEqualTo(double value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'distanciaKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  distanciaKmGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'distanciaKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  distanciaKmLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'distanciaKm',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  distanciaKmBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'distanciaKm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  duracaoMinutosEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'duracaoMinutos', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  duracaoMinutosGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'duracaoMinutos',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  duracaoMinutosLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'duracaoMinutos',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  duracaoMinutosBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'duracaoMinutos',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  finalizadaEmIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'finalizadaEm'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  finalizadaEmIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'finalizadaEm'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  finalizadaEmEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'finalizadaEm', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  finalizadaEmGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'finalizadaEm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  finalizadaEmLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'finalizadaEm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  finalizadaEmBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'finalizadaEm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmFinalIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'kmFinal'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  kmFinalIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'kmFinal'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmFinalEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kmFinal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  kmFinalGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kmFinal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmFinalLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kmFinal',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmFinalBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kmFinal',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmInicialEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'kmInicial',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  kmInicialGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kmInicial',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmInicialLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kmInicial',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> kmInicialBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kmInicial',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLatitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'origemLatitude'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLatitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'origemLatitude'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLatitudeEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'origemLatitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLatitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'origemLatitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLatitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'origemLatitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLatitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'origemLatitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLongitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'origemLongitude'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLongitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'origemLongitude'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLongitudeEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'origemLongitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLongitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'origemLongitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLongitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'origemLongitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  origemLongitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'origemLongitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> otimizadaEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'otimizada', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> ownerEmailEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'ownerEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> ownerEmailBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerEmail',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'ownerEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'ownerEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'ownerEmail',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> ownerEmailMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'ownerEmail',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerEmail', value: ''),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  ownerEmailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'ownerEmail', value: ''),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  pacotesImportadosEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pacotesImportados', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  pacotesImportadosGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pacotesImportados',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  pacotesImportadosLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pacotesImportados',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  pacotesImportadosBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pacotesImportados',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  paradasImportadasEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'paradasImportadas', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  paradasImportadasGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'paradasImportadas',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  paradasImportadasLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'paradasImportadas',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  paradasImportadasBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'paradasImportadas',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  romaneioLayoutEqualTo(ImportRomaneioLayout value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'romaneioLayout', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  romaneioLayoutGreaterThan(
    ImportRomaneioLayout value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'romaneioLayout',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  romaneioLayoutLessThan(ImportRomaneioLayout value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'romaneioLayout',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  romaneioLayoutBetween(
    ImportRomaneioLayout lower,
    ImportRomaneioLayout upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'romaneioLayout',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rotaGeometriaJson'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rotaGeometriaJson'),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rotaGeometriaJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rotaGeometriaJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rotaGeometriaJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rotaGeometriaJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rotaGeometriaJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rotaGeometriaJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rotaGeometriaJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rotaGeometriaJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rotaGeometriaJson', value: ''),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  rotaGeometriaJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rotaGeometriaJson', value: ''),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> statusEqualTo(
    RotaStatus value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> statusGreaterThan(
    RotaStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> statusLessThan(
    RotaStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> statusBetween(
    RotaStatus lower,
    RotaStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'titulo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'titulo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'titulo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'titulo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'titulo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'titulo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'titulo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'titulo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> tituloIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'titulo', value: ''),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  tituloIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'titulo', value: ''),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> valorPagoEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'valorPago',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition>
  valorPagoGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'valorPago',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> valorPagoLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'valorPago',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterFilterCondition> valorPagoBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'valorPago',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }
}

extension RotaRecordQueryObject
    on QueryBuilder<RotaRecord, RotaRecord, QFilterCondition> {}

extension RotaRecordQueryLinks
    on QueryBuilder<RotaRecord, RotaRecord, QFilterCondition> {}

extension RotaRecordQuerySortBy
    on QueryBuilder<RotaRecord, RotaRecord, QSortBy> {
  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByArquivoPlanilhaImportada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arquivoPlanilhaImportada', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByArquivoPlanilhaImportadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arquivoPlanilhaImportada', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByCriadaEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadaEm', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByCriadaEmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadaEm', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByDistanciaKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanciaKm', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByDistanciaKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanciaKm', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByDuracaoMinutos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duracaoMinutos', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByDuracaoMinutosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duracaoMinutos', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByFinalizadaEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalizadaEm', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByFinalizadaEmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalizadaEm', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByKmFinal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmFinal', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByKmFinalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmFinal', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByKmInicial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmInicial', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByKmInicialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmInicial', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByOrigemLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLatitude', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByOrigemLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLatitude', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByOrigemLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLongitude', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByOrigemLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLongitude', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByOtimizada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otimizada', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByOtimizadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otimizada', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByOwnerEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerEmail', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByOwnerEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerEmail', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByPacotesImportados() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pacotesImportados', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByPacotesImportadosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pacotesImportados', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByParadasImportadas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paradasImportadas', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByParadasImportadasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paradasImportadas', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByRomaneioLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByRomaneioLayoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByRotaGeometriaJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaGeometriaJson', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  sortByRotaGeometriaJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaGeometriaJson', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByTitulo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titulo', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByTituloDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titulo', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByValorPago() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorPago', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> sortByValorPagoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorPago', Sort.desc);
    });
  }
}

extension RotaRecordQuerySortThenBy
    on QueryBuilder<RotaRecord, RotaRecord, QSortThenBy> {
  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByArquivoPlanilhaImportada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arquivoPlanilhaImportada', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByArquivoPlanilhaImportadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arquivoPlanilhaImportada', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByCriadaEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadaEm', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByCriadaEmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadaEm', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByDistanciaKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanciaKm', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByDistanciaKmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'distanciaKm', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByDuracaoMinutos() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duracaoMinutos', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByDuracaoMinutosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'duracaoMinutos', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByFinalizadaEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalizadaEm', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByFinalizadaEmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'finalizadaEm', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByKmFinal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmFinal', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByKmFinalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmFinal', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByKmInicial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmInicial', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByKmInicialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kmInicial', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByOrigemLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLatitude', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByOrigemLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLatitude', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByOrigemLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLongitude', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByOrigemLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'origemLongitude', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByOtimizada() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otimizada', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByOtimizadaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otimizada', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByOwnerEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerEmail', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByOwnerEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerEmail', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByPacotesImportados() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pacotesImportados', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByPacotesImportadosDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pacotesImportados', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByParadasImportadas() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paradasImportadas', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByParadasImportadasDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'paradasImportadas', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByRomaneioLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByRomaneioLayoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByRotaGeometriaJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaGeometriaJson', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy>
  thenByRotaGeometriaJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaGeometriaJson', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByTitulo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titulo', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByTituloDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'titulo', Sort.desc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByValorPago() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorPago', Sort.asc);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QAfterSortBy> thenByValorPagoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valorPago', Sort.desc);
    });
  }
}

extension RotaRecordQueryWhereDistinct
    on QueryBuilder<RotaRecord, RotaRecord, QDistinct> {
  QueryBuilder<RotaRecord, RotaRecord, QDistinct>
  distinctByArquivoPlanilhaImportada({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'arquivoPlanilhaImportada',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByCriadaEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'criadaEm');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByDistanciaKm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'distanciaKm');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByDuracaoMinutos() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'duracaoMinutos');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByFinalizadaEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'finalizadaEm');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByKmFinal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kmFinal');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByKmInicial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kmInicial');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByOrigemLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'origemLatitude');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByOrigemLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'origemLongitude');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByOtimizada() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otimizada');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByOwnerEmail({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerEmail', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct>
  distinctByPacotesImportados() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pacotesImportados');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct>
  distinctByParadasImportadas() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'paradasImportadas');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByRomaneioLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'romaneioLayout');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByRotaGeometriaJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'rotaGeometriaJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByTitulo({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'titulo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<RotaRecord, RotaRecord, QDistinct> distinctByValorPago() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valorPago');
    });
  }
}

extension RotaRecordQueryProperty
    on QueryBuilder<RotaRecord, RotaRecord, QQueryProperty> {
  QueryBuilder<RotaRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<RotaRecord, String?, QQueryOperations>
  arquivoPlanilhaImportadaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'arquivoPlanilhaImportada');
    });
  }

  QueryBuilder<RotaRecord, DateTime, QQueryOperations> criadaEmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'criadaEm');
    });
  }

  QueryBuilder<RotaRecord, double, QQueryOperations> distanciaKmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'distanciaKm');
    });
  }

  QueryBuilder<RotaRecord, int, QQueryOperations> duracaoMinutosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'duracaoMinutos');
    });
  }

  QueryBuilder<RotaRecord, DateTime?, QQueryOperations> finalizadaEmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'finalizadaEm');
    });
  }

  QueryBuilder<RotaRecord, double?, QQueryOperations> kmFinalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kmFinal');
    });
  }

  QueryBuilder<RotaRecord, double, QQueryOperations> kmInicialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kmInicial');
    });
  }

  QueryBuilder<RotaRecord, double?, QQueryOperations> origemLatitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'origemLatitude');
    });
  }

  QueryBuilder<RotaRecord, double?, QQueryOperations>
  origemLongitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'origemLongitude');
    });
  }

  QueryBuilder<RotaRecord, bool, QQueryOperations> otimizadaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otimizada');
    });
  }

  QueryBuilder<RotaRecord, String, QQueryOperations> ownerEmailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerEmail');
    });
  }

  QueryBuilder<RotaRecord, int, QQueryOperations> pacotesImportadosProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pacotesImportados');
    });
  }

  QueryBuilder<RotaRecord, int, QQueryOperations> paradasImportadasProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'paradasImportadas');
    });
  }

  QueryBuilder<RotaRecord, ImportRomaneioLayout, QQueryOperations>
  romaneioLayoutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'romaneioLayout');
    });
  }

  QueryBuilder<RotaRecord, String?, QQueryOperations>
  rotaGeometriaJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rotaGeometriaJson');
    });
  }

  QueryBuilder<RotaRecord, RotaStatus, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }

  QueryBuilder<RotaRecord, String, QQueryOperations> tituloProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'titulo');
    });
  }

  QueryBuilder<RotaRecord, double, QQueryOperations> valorPagoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valorPago');
    });
  }
}
