import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int MAX_SUGGESTIONS = 5;

  // List of Tunisian cities for initial suggestions
  final List<String> _tunisianCities = [
    'Tunis', 'Sfax', 'Sousse', 'Kairouan', 'Bizerte',
    'Gabès', 'Ariana', 'Ben Arous', 'Manouba', 'Nabeul',
    'Zaghouan', 'Siliana', 'Kef', 'Jendouba', 'Kasserine',
    'Sidi Bouzid', 'Mahdia', 'Monastir', 'Sfax', 'Gafsa',
    'Tozeur', 'Kebili', 'Tataouine', 'Medenine'
  ];

  // Search algorithm: Case-insensitive search that matches any part of the city name
  // Time Complexity: O(n) where n is the number of cities
  // Space Complexity: O(k) where k is the number of suggestions
  List<String> getSuggestions(String query) {
    if (query.isEmpty) {
      return [];
    }

    final lowercaseQuery = query.toLowerCase();
    final suggestions = <String>[];

    // First, search in the local list for immediate suggestions
    for (final city in _tunisianCities) {
      if (suggestions.length >= MAX_SUGGESTIONS) break;
      
      final lowercaseCity = city.toLowerCase();
      if (lowercaseCity.contains(lowercaseQuery)) {
        suggestions.add(city);
      }
    }

    // If we have enough suggestions, return them
    if (suggestions.length >= MAX_SUGGESTIONS) {
      return suggestions;
    }

    // If we need more suggestions, search in Firestore
    _searchInFirestore(lowercaseQuery, suggestions);

    return suggestions;
  }

  // Search in Firestore for additional suggestions
  Future<void> _searchInFirestore(String query, List<String> suggestions) async {
    try {
      final snapshot = await _firestore
          .collection('cities')
          .where('lowercaseName', isGreaterThanOrEqualTo: query)
          .where('lowercaseName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(MAX_SUGGESTIONS - suggestions.length)
          .get();

      for (final doc in snapshot.docs) {
        if (suggestions.length >= MAX_SUGGESTIONS) break;
        
        final cityName = doc.data()['name'] as String;
        if (!suggestions.contains(cityName)) {
          suggestions.add(cityName);
        }
      }
    } catch (e) {
      print('Error searching cities in Firestore: $e');
    }
  }

  // Add a new city to Firestore
  Future<void> addCity(String cityName) async {
    try {
      final lowercaseName = cityName.toLowerCase();
      await _firestore.collection('cities').doc(lowercaseName).set({
        'name': cityName,
        'lowercaseName': lowercaseName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding city to Firestore: $e');
    }
  }

  final List<String> _cities = [
    'Tunis',
    'Sfax',
    'Sousse',
    'Kairouan',
    'Bizerte',
    'Gabès',
    'Ariana',
    'Gafsa',
    'Monastir',
    'La Marsa',
    'La Goulette',
    'Carthage',
    'Sidi Bou Said',
    'La Soukra',
    'Ben Arous',
    'Nabeul',
    'Hammamet',
    'Kélibia',
    'Zaghouan',
    'Beja',
    'Jendouba',
    'Kef',
    'Siliana',
    'Kasserine',
    'Sidi Bouzid',
    'Mahdia',
    'Medenine',
    'Tataouine',
    'Tozeur',
    'Kebili',
  ];

  Future<List<String>> getCitySuggestions(String query) async {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return _tunisianCities
        .where((city) => city.toLowerCase().startsWith(lowercaseQuery))
        .toList();
  }
} 