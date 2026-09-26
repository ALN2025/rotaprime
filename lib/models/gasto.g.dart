// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gasto.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGastoCollection on Isar {
  IsarCollection<Gasto> get gastos => this.collection();
}

const GastoSchema = CollectionSchema(
  name: r'Gasto',
  id: 4941028211822366755,
  properties: {
    r'criadoEm': PropertySchema(
      id: 0,
      name: r'criadoEm',
      type: IsarType.dateTime,
    ),
    r'fotoPath': PropertySchema(
      id: 1,
      name: r'fotoPath',
      type: IsarType.string,
    ),
    r'rotaId': PropertySchema(id: 2, name: r'rotaId', type: IsarType.long),
    r'tipo': PropertySchema(id: 3, name: r'tipo', type: IsarType.string),
    r'valor': PropertySchema(id: 4, name: r'valor', type: IsarType.double),
  },

  estimateSize: _gastoEstimateSize,
  serialize: _gastoSerialize,
  deserialize: _gastoDeserialize,
  deserializeProp: _gastoDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _gastoGetId,
  getLinks: _gastoGetLinks,
  attach: _gastoAttach,
  version: '3.3.2',
);

int _gastoEstimateSize(
  Gasto object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.fotoPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.tipo.length * 3;
  return bytesCount;
}

void _gastoSerialize(
  Gasto object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.criadoEm);
  writer.writeString(offsets[1], object.fotoPath);
  writer.writeLong(offsets[2], object.rotaId);
  writer.writeString(offsets[3], object.tipo);
  writer.writeDouble(offsets[4], object.valor);
}

Gasto _gastoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Gasto();
  object.criadoEm = reader.readDateTime(offsets[0]);
  object.fotoPath = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.rotaId = reader.readLong(offsets[2]);
  object.tipo = reader.readString(offsets[3]);
  object.valor = reader.readDouble(offsets[4]);
  return object;
}

P _gastoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _gastoGetId(Gasto object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _gastoGetLinks(Gasto object) {
  return [];
}

void _gastoAttach(IsarCollection<dynamic> col, Id id, Gasto object) {
  object.id = id;
}

extension GastoQueryWhereSort on QueryBuilder<Gasto, Gasto, QWhere> {
  QueryBuilder<Gasto, Gasto, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GastoQueryWhere on QueryBuilder<Gasto, Gasto, QWhereClause> {
  QueryBuilder<Gasto, Gasto, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Gasto, Gasto, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterWhereClause> idBetween(
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

extension GastoQueryFilter on QueryBuilder<Gasto, Gasto, QFilterCondition> {
  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> criadoEmEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'criadoEm', value: value),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> criadoEmGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'criadoEm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> criadoEmLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'criadoEm',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> criadoEmBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'criadoEm',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'fotoPath'),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'fotoPath'),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fotoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fotoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fotoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fotoPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fotoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fotoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fotoPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fotoPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fotoPath', value: ''),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> fotoPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fotoPath', value: ''),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> rotaIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rotaId', value: value),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> rotaIdGreaterThan(
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

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> rotaIdLessThan(
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

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> rotaIdBetween(
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

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tipo',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tipo',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tipo',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tipo', value: ''),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> tipoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tipo', value: ''),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> valorEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'valor',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> valorGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'valor',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> valorLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'valor',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterFilterCondition> valorBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'valor',
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

extension GastoQueryObject on QueryBuilder<Gasto, Gasto, QFilterCondition> {}

extension GastoQueryLinks on QueryBuilder<Gasto, Gasto, QFilterCondition> {}

extension GastoQuerySortBy on QueryBuilder<Gasto, Gasto, QSortBy> {
  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByCriadoEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadoEm', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByCriadoEmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadoEm', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByFotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fotoPath', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByFotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fotoPath', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByRotaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByRotaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByTipo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByTipoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> sortByValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.desc);
    });
  }
}

extension GastoQuerySortThenBy on QueryBuilder<Gasto, Gasto, QSortThenBy> {
  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByCriadoEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadoEm', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByCriadoEmDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'criadoEm', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByFotoPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fotoPath', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByFotoPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fotoPath', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByRotaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByRotaIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rotaId', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByTipo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByTipoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tipo', Sort.desc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.asc);
    });
  }

  QueryBuilder<Gasto, Gasto, QAfterSortBy> thenByValorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valor', Sort.desc);
    });
  }
}

extension GastoQueryWhereDistinct on QueryBuilder<Gasto, Gasto, QDistinct> {
  QueryBuilder<Gasto, Gasto, QDistinct> distinctByCriadoEm() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'criadoEm');
    });
  }

  QueryBuilder<Gasto, Gasto, QDistinct> distinctByFotoPath({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fotoPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Gasto, Gasto, QDistinct> distinctByRotaId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rotaId');
    });
  }

  QueryBuilder<Gasto, Gasto, QDistinct> distinctByTipo({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tipo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Gasto, Gasto, QDistinct> distinctByValor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valor');
    });
  }
}

extension GastoQueryProperty on QueryBuilder<Gasto, Gasto, QQueryProperty> {
  QueryBuilder<Gasto, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Gasto, DateTime, QQueryOperations> criadoEmProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'criadoEm');
    });
  }

  QueryBuilder<Gasto, String?, QQueryOperations> fotoPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fotoPath');
    });
  }

  QueryBuilder<Gasto, int, QQueryOperations> rotaIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rotaId');
    });
  }

  QueryBuilder<Gasto, String, QQueryOperations> tipoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tipo');
    });
  }

  QueryBuilder<Gasto, double, QQueryOperations> valorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valor');
    });
  }
}
