// visa_initializer.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'visa_data.dart';

Future<void> initializeVisaData() async {
  final visaCollection = FirebaseFirestore.instance.collection('VisaRequirements');

  for (var countryData in visaCountries) {
    final docRef = visaCollection.doc(countryData['country']);
    final snapshot = await docRef.get();

    if (!snapshot.exists) {
      await docRef.set({
        'requiresVisa': countryData['requiresVisa'],
        'info': countryData['info'],
      });
    }
  }
}