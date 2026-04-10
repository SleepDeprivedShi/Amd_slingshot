import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';

class FoodLog {
  final String id;
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fats;
  final DateTime date;

  FoodLog({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.date,
  });
}

class FirebaseService extends ChangeNotifier {
  static bool isMockMode = false;
  
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  
  // Mock State
  final List<FoodLog> _mockLogs = [];
  bool get isLoading => _isLoading;
  bool _isLoading = false;

  void setMockDemo() {
    isMockMode = true;
    _isAuthenticated = true;
    
    // Add dummy data for stats
    final now = DateTime.now();
    _mockLogs.add(FoodLog(id: '1', name: 'Oatmeal', calories: 350, protein: 12, carbs: 55, fats: 8, date: now));
    _mockLogs.add(FoodLog(id: '2', name: 'Chicken Salad', calories: 420, protein: 35, carbs: 12, fats: 20, date: now.subtract(const Duration(days: 1))));
    _mockLogs.add(FoodLog(id: '3', name: 'Protein Shake', calories: 200, protein: 30, carbs: 5, fats: 3, date: now.subtract(const Duration(days: 2))));
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true; notifyListeners();
    if (isMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      _isAuthenticated = true;
    } else {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
        _isAuthenticated = true;
      } catch (e) {
        _isLoading = false; notifyListeners();
        throw Exception(e.toString());
      }
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> signup(String email, String password) async {
    _isLoading = true; notifyListeners();
    if (isMockMode) {
      await Future.delayed(const Duration(seconds: 1));
      _isAuthenticated = true;
    } else {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
        _isAuthenticated = true;
      } catch (e) {
        _isLoading = false; notifyListeners();
        throw Exception(e.toString());
      }
    }
    _isLoading = false; notifyListeners();
  }

  Future<void> logout() async {
    if (!isMockMode) {
      await FirebaseAuth.instance.signOut();
    }
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> logFood(AnalysisResult result) async {
    if (isMockMode) {
      _mockLogs.add(FoodLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result.foodName,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fats: result.fats,
        date: DateTime.now(),
      ));
      notifyListeners();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('logs').add({
        'name': result.foodName,
        'calories': result.calories,
        'protein': result.protein,
        'carbs': result.carbs,
        'fats': result.fats,
        'date': Timestamp.now(),
      });
      notifyListeners();
    }
  }

  Future<List<FoodLog>> fetchLogs() async {
    if (isMockMode) {
      return _mockLogs.reversed.toList();
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('logs')
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return FoodLog(
        id: doc.id,
        name: data['name'],
        calories: data['calories'],
        protein: data['protein'],
        carbs: data['carbs'],
        fats: data['fats'],
        date: (data['date'] as Timestamp).toDate(),
      );
    }).toList();
  }
}
