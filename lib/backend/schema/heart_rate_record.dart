import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class HeartRateRecord extends FirestoreRecord {
  HeartRateRecord._(
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
          ? parent.collection('heartRate')
          : FirebaseFirestore.instance.collectionGroup('heartRate');

  static DocumentReference createDoc(DocumentReference parent, {String? id}) =>
      parent.collection('heartRate').doc(id);

  static Stream<HeartRateRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => HeartRateRecord.fromSnapshot(s));

  static Future<HeartRateRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => HeartRateRecord.fromSnapshot(s));

  static HeartRateRecord fromSnapshot(DocumentSnapshot snapshot) =>
      HeartRateRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static HeartRateRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      HeartRateRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'HeartRateRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is HeartRateRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createHeartRateRecordData({
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

class HeartRateRecordDocumentEquality implements Equality<HeartRateRecord> {
  const HeartRateRecordDocumentEquality();

  @override
  bool equals(HeartRateRecord? e1, HeartRateRecord? e2) {
    return e1?.time == e2?.time && e1?.value == e2?.value;
  }

  @override
  int hash(HeartRateRecord? e) =>
      const ListEquality().hash([e?.time, e?.value]);

  @override
  bool isValidKey(Object? o) => o is HeartRateRecord;
}
