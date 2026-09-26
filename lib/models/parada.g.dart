// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parada.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetParadaCollection on Isar {
  IsarCollection<Parada> get paradas => this.collection();
}

const ParadaSchema = CollectionSchema(
  name: r'Parada',
  id: 406628821634077427,
  properties: {
    r'bairro': PropertySchema(id: 0, name: r'bairro', type: IsarType.string),
    r'city': PropertySchema(id: 1, name: r'city', type: IsarType.string),
    r'destinationAddress': PropertySchema(
      id: 2,
      name: r'destinationAddress',
      type: IsarType.string,
    ),
    r'entregaComercial': PropertySchema(
      id: 3,
      name: r'entregaComercial',
      type: IsarType.bool,
    ),
    r'entregue': PropertySchema(id: 4, name: r'entregue', type: IsarType.bool),
    r'falha': PropertySchema(id: 5, name: r'falha', type: IsarType.bool),
    r'latitude': PropertySchema(
      id: 6,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 7,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'ordemExibicao': PropertySchema(
      id: 8,
      name: r'ordemExibicao',
      type: IsarType.long,
    ),
    r'prazoEntrega': PropertySchema(
      id: 9,
      name: r'prazoEntrega',
      type: IsarType.string,
    ),
    r'quantidadePacotes': PropertySchema(
      id: 10,
      name: r'quantidadePacotes',
      type: IsarType.long,
    ),
    r'rawLine': PropertySchema(id: 11, name: r'rawLine', type: IsarType.string),
    r'romaneioCarrier': PropertySchema(
      id: 12,
      name: r'romaneioCarrier',
      type: IsarType.byte,
      enumMap: _ParadaromaneioCarrierEnumValueMap,
    ),
    r'romaneioLayout': PropertySchema(
      id: 13,
      name: r'romaneioLayout',
      type: IsarType.byte,
      enumMap: _ParadaromaneioLayoutEnumValueMap,
    ),
    r'rotaId': PropertySchema(id: 14, name: r'rotaId', type: IsarType.long),
    r'sequence': PropertySchema(id: 15, name: r'sequence', type: IsarType.long),
    r'spxTn': PropertySchema(id: 16, name: r'spxTn', type: IsarType.string),
    r'stop': PropertySchema(id: 17, name: r'stop', type: IsarType.long),
    r'zipcode': PropertySchema(id: 18, name: r'zipcode', type: IsarType.string),
  },

  estimateSize: _paradaEstimateSize,
  serialize: _paradaSerialize,
  deserialize: _paradaDeserialize,
  deserializeProp: _paradaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _paradaGetId,
  getLinks: _paradaGetLinks,
  attach: _paradaAttach,
  version: '3.3.2',
);

int _paradaEstimateSize(
  Parada object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.bairro.length * 3;
  bytesCount += 3 + object.city.length * 3;
  bytesCount += 3 + object.destinationAddress.length * 3;
  bytesCount += 3 + object.prazoEntrega.length * 3;
  bytesCount += 3 + object.rawLine.length * 3;
  bytesCount += 3 + object.spxTn.length * 3;
  bytesCount += 3 + object.zipcode.length * 3;
  return bytesCount;
}

void _paradaSerialize(
  Parada object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.bairro);
  writer.writeString(offsets[1], object.city);
  writer.writeString(offsets[2], object.destinationAddress);
  writer.writeBool(offsets[3], object.entregaComercial);
  writer.writeBool(offsets[4], object.entregue);
  writer.writeBool(offsets[5], object.falha);
  writer.writeDouble(offsets[6], object.latitude);
  writer.writeDouble(offsets[7], object.longitude);
  writer.writeLong(offsets[8], object.ordemExibicao);
  writer.writeString(offsets[9], object.prazoEntrega);
  writer.writeLong(offsets[10], object.quantidadePacotes);
  writer.writeString(offsets[11], object.rawLine);
  writer.writeByte(offsets[12], object.romaneioCarrier.index);
  writer.writeByte(offsets[13], object.romaneioLayout.index);
  writer.writeLong(offsets[14], object.rotaId);
  writer.writeLong(offsets[15], object.sequence);
  writer.writeString(offsets[16], object.spxTn);
  writer.writeLong(offsets[17], object.stop);
  writer.writeString(offsets[18], object.zipcode);
}

Parada _paradaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Parada();
  object.bairro = reader.readString(offsets[0]);
  object.city = reader.readString(offsets[1]);
  object.destinationAddress = reader.readString(offsets[2]);
  object.entregaComercial = reader.readBool(offsets[3]);
  object.entregue = reader.readBool(offsets[4]);
  object.falha = reader.readBool(offsets[5]);
  object.id = id;
  object.latitude = reader.readDoubleOrNull(offsets[6]);
  object.longitude = reader.readDoubleOrNull(offsets[7]);
  object.ordemExibicao = reader.readLong(offsets[8]);
  object.prazoEntrega = reader.readString(offsets[9]);
  object.quantidadePacotes = reader.readLong(offsets[10]);
  object.rawLine = reader.readString(offsets[11]);
  object.romaneioCarrier =
      _ParadaromaneioCarrierValueEnumMap[reader.readByteOrNull(offsets[12])] ??
      RomaneioCarrier.shopee;
  object.romaneioLayout =
      _ParadaromaneioLayoutValueEnumMap[reader.readByteOrNull(offsets[13])] ??
      ImportRomaneioLayout.padrao;
  object.rotaId = reader.readLong(offsets[14]);
  object.sequence = reader.readLong(offsets[15]);
  object.spxTn = reader.readString(offsets[16]);
  object.stop = reader.readLong(offsets[17]);
  object.zipcode = reader.readString(offsets[18]);
  return object;
}

P _paradaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readDoubleOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (_ParadaromaneioCarrierValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              RomaneioCarrier.shopee)
          as P;
    case 13:
      return (_ParadaromaneioLayoutValueEnumMap[reader.readByteOrNull(
                offset,
              )] ??
              ImportRomaneioLayout.padrao)
          as P;
    case 14:
      return (reader.readLong(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readString(offset)) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ParadaromaneioCarrierEnumValueMap = {
  'shopee': 0,
  'rjRelatorioEntregas': 1,
  'protocoloCarregamento': 2,
  'magalog': 3,
  'loggi': 4,
  'icsDelivery': 5,
  'generico': 6,
};
const _ParadaromaneioCarrierValueEnumMap = {
  0: RomaneioCarrier.shopee,
  1: RomaneioCarrier.rjRelatorioEntregas,
  2: RomaneioCarrier.protocoloCarregamento,
  3: RomaneioCarrier.magalog,
  4: RomaneioCarrier.loggi,
  5: RomaneioCarrier.icsDelivery,
  6: RomaneioCarrier.generico,
};
const _ParadaromaneioLayoutEnumValueMap = {
  'padrao': 0,
  'shopeeOrdemPacote': 1,
  'pdfRelatorioRj': 2,
  'pdfProtocoloEntrega': 3,
};
const _ParadaromaneioLayoutValueEnumMap = {
  0: ImportRomaneioLayout.padrao,
  1: ImportRomaneioLayout.shopeeOrdemPacote,
  2: ImportRomaneioLayout.pdfRelatorioRj,
  3: ImportRomaneioLayout.pdfProtocoloEntrega,
};

Id _paradaGetId(Parada object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _paradaGetLinks(Parada object) {
  return [];
}

void _paradaAttach(IsarCollection<dynamic> col, Id id, Parada object) {
  object.id = id;
}

extension ParadaQueryWhereSort on QueryBuilder<Parada, Parada, QWhere> {
  QueryBuilder<Parada, Parada, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ParadaQueryWhere on QueryBuilder<Parada, Parada, QWhereClause> {
  QueryBuilder<Parada, Parada, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Parada, Parada, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Parada, Parada, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterWhereClause> idBetween(
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

extension ParadaQueryFilter on QueryBuilder<Parada, Parada, QFilterCondition> {
  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'bairro',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'bairro',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'bairro',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'bairro',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'bairro',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'bairro',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'bairro',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'bairro',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'bairro', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> bairroIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'bairro', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'city',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'city',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'city', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> cityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'city', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> destinationAddressEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'destinationAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'destinationAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'destinationAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> destinationAddressBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'destinationAddress',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'destinationAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'destinationAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'destinationAddress',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> destinationAddressMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'destinationAddress',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'destinationAddress', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  destinationAddressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'destinationAddress', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> entregaComercialEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entregaComercial', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> entregueEqualTo(
    bool value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entregue', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> falhaEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'falha', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Parada, Parada, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Parada, Parada, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Parada, Parada, QAfterFilterCondition> latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> longitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'longitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> ordemExibicaoEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ordemExibicao', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> ordemExibicaoGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ordemExibicao',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> ordemExibicaoLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ordemExibicao',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> ordemExibicaoBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ordemExibicao',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'prazoEntrega',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'prazoEntrega',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'prazoEntrega',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'prazoEntrega',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'prazoEntrega',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'prazoEntrega',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'prazoEntrega',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'prazoEntrega',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'prazoEntrega', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> prazoEntregaIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'prazoEntrega', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> quantidadePacotesEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'quantidadePacotes', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  quantidadePacotesGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'quantidadePacotes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> quantidadePacotesLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'quantidadePacotes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> quantidadePacotesBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'quantidadePacotes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rawLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rawLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rawLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rawLine',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rawLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rawLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rawLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rawLine',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rawLine', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rawLineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rawLine', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioCarrierEqualTo(
    RomaneioCarrier value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'romaneioCarrier', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition>
  romaneioCarrierGreaterThan(RomaneioCarrier value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'romaneioCarrier',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioCarrierLessThan(
    RomaneioCarrier value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'romaneioCarrier',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioCarrierBetween(
    RomaneioCarrier lower,
    RomaneioCarrier upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'romaneioCarrier',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioLayoutEqualTo(
    ImportRomaneioLayout value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'romaneioLayout', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioLayoutGreaterThan(
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

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioLayoutLessThan(
    ImportRomaneioLayout value, {
    bool include = false,
  }) {
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

  QueryBuilder<Parada, Parada, QAfterFilterCondition> romaneioLayoutBetween(
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

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rotaIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rotaId', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rotaIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rotaId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rotaIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rotaId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> rotaIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rotaId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> sequenceEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sequence', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> sequenceGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> sequenceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sequence',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> sequenceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sequence',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'spxTn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'spxTn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'spxTn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'spxTn',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'spxTn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'spxTn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'spxTn',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'spxTn',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'spxTn', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> spxTnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'spxTn', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> stopEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'stop', value: value),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> stopGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'stop',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> stopLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'stop',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> stopBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'stop',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'zipcode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'zipcode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'zipcode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'zipcode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'zipcode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'zipcode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'zipcode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'zipcode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'zipcode', value: ''),
      );
    });
  }

  QueryBuilder<Parada, Parada, QAfterFilterCondition> zipcodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'zipcode', value: ''),
      );
    });
  }
}

extension ParadaQueryObject on QueryBuilder<Parada, Parada, QFilterCondition> {}

extension ParadaQueryLinks on QueryBuilder<Parada, Parada, QFilterCondition> {}

extension ParadaQuerySortBy on QueryBuilder<Parada, Parada, QSortBy> {
  QueryBuilder<Parada, Parada, QAfterSortBy> sortByBairro() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bairro', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByBairroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bairro', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByDestinationAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinationAddress', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByDestinationAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinationAddress', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByEntregaComercial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregaComercial', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByEntregaComercialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregaComercial', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByEntregue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregue', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByEntregueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregue', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByFalha() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'falha', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByFalhaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'falha', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByOrdemExibicao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ordemExibicao', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByOrdemExibicaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ordemExibicao', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByPrazoEntrega() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prazoEntrega', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByPrazoEntregaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prazoEntrega', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByQuantidadePacotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantidadePacotes', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByQuantidadePacotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantidadePacotes', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRawLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawLine', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRawLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawLine', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRomaneioCarrier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioCarrier', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRomaneioCarrierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioCarrier', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRomaneioLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRomaneioLayoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRotaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByRotaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortBySpxTn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spxTn', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortBySpxTnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spxTn', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByStop() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stop', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByStopDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stop', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByZipcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zipcode', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> sortByZipcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zipcode', Sort.desc);
    });
  }
}

extension ParadaQuerySortThenBy on QueryBuilder<Parada, Parada, QSortThenBy> {
  QueryBuilder<Parada, Parada, QAfterSortBy> thenByBairro() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bairro', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByBairroDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bairro', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByDestinationAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinationAddress', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByDestinationAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'destinationAddress', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByEntregaComercial() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregaComercial', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByEntregaComercialDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregaComercial', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByEntregue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregue', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByEntregueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entregue', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByFalha() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'falha', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByFalhaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'falha', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByOrdemExibicao() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ordemExibicao', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByOrdemExibicaoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ordemExibicao', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByPrazoEntrega() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prazoEntrega', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByPrazoEntregaDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'prazoEntrega', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByQuantidadePacotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantidadePacotes', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByQuantidadePacotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantidadePacotes', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRawLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawLine', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRawLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rawLine', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRomaneioCarrier() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioCarrier', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRomaneioCarrierDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioCarrier', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRomaneioLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRomaneioLayoutDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'romaneioLayout', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRotaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByRotaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenBySequenceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sequence', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenBySpxTn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spxTn', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenBySpxTnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'spxTn', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByStop() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stop', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByStopDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stop', Sort.desc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByZipcode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zipcode', Sort.asc);
    });
  }

  QueryBuilder<Parada, Parada, QAfterSortBy> thenByZipcodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'zipcode', Sort.desc);
    });
  }
}

extension ParadaQueryWhereDistinct on QueryBuilder<Parada, Parada, QDistinct> {
  QueryBuilder<Parada, Parada, QDistinct> distinctByBairro({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bairro', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByCity({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'city', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByDestinationAddress({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'destinationAddress',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByEntregaComercial() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entregaComercial');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByEntregue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entregue');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByFalha() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'falha');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByOrdemExibicao() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ordemExibicao');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByPrazoEntrega({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'prazoEntrega', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByQuantidadePacotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantidadePacotes');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByRawLine({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rawLine', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByRomaneioCarrier() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'romaneioCarrier');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByRomaneioLayout() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'romaneioLayout');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByRotaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rotaId');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctBySequence() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sequence');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctBySpxTn({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'spxTn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByStop() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stop');
    });
  }

  QueryBuilder<Parada, Parada, QDistinct> distinctByZipcode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'zipcode', caseSensitive: caseSensitive);
    });
  }
}

extension ParadaQueryProperty on QueryBuilder<Parada, Parada, QQueryProperty> {
  QueryBuilder<Parada, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> bairroProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bairro');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> cityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'city');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> destinationAddressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'destinationAddress');
    });
  }

  QueryBuilder<Parada, bool, QQueryOperations> entregaComercialProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entregaComercial');
    });
  }

  QueryBuilder<Parada, bool, QQueryOperations> entregueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entregue');
    });
  }

  QueryBuilder<Parada, bool, QQueryOperations> falhaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'falha');
    });
  }

  QueryBuilder<Parada, double?, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<Parada, double?, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<Parada, int, QQueryOperations> ordemExibicaoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ordemExibicao');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> prazoEntregaProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'prazoEntrega');
    });
  }

  QueryBuilder<Parada, int, QQueryOperations> quantidadePacotesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantidadePacotes');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> rawLineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rawLine');
    });
  }

  QueryBuilder<Parada, RomaneioCarrier, QQueryOperations>
  romaneioCarrierProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'romaneioCarrier');
    });
  }

  QueryBuilder<Parada, ImportRomaneioLayout, QQueryOperations>
  romaneioLayoutProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'romaneioLayout');
    });
  }

  QueryBuilder<Parada, int, QQueryOperations> rotaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rotaId');
    });
  }

  QueryBuilder<Parada, int, QQueryOperations> sequenceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sequence');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> spxTnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'spxTn');
    });
  }

  QueryBuilder<Parada, int, QQueryOperations> stopProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stop');
    });
  }

  QueryBuilder<Parada, String, QQueryOperations> zipcodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'zipcode');
    });
  }
}
