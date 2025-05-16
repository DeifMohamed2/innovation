import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TemperatureRecord extends FirestoreRecord {
  TemperatureRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "time" field.
  DateTime? _time;
  DateTime? get time => _time;
  bool hasTime() => _time != null;

  // "value" field.
  double? _value;
  double get value => _value ?? 0.0;
  bool hasValue() => _value != null;

  DocumentReference get parentReference => reference.parent.parent!;

  void _initializeFields() {
    _time = snapshotData['time'] as DateTime?;
    _value = castToType<double>(snapshotData['value']);
  }

  static Query<Map<String, dynamic>> collection([DocumentReference? parent]) =>
      parent != null
          ? parent.collection('temperature')
          : FirebaseFirestore.instance.collectionGroup('temperature');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('temperature').doc(id);

  static Stream<TemperatureRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TemperatureRecord.fromSnapshot(s));

  static Future<TemperatureRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TemperatureRecord.fromSnapshot(s));

  static TemperatureRecord fromSnapshot(DocumentSnapshot snapshot) =>
      TemperatureRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TemperatureRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TemperatureRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TemperatureRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TemperatureRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTemperatureRecordData({
  DateTime? time,
  double? value,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'time': time,
      'value': value,
    }.withoutNulls,
  );

  return firestoreData;
}

class TemperatureRecordDocumentEquality implements Equality<TemperatureRecord> {
  const TemperatureRecordDocumentEquality();

  @override
  bool equals(TemperatureRecord? e1, TemperatureRecord? e2) {
    return e1?.time == e2?.time && e1?.value == e2?.value;
  }

  @override
  int hash(TemperatureRecord? e) =>
      const ListEquality().hash([e?.time, e?.value]);

  @override
  bool isValidKey(Object? o) => o is TemperatureRecord;
}
