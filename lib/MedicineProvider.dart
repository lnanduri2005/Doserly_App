import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../services/notification_service.dart';

class MedicineProvider with ChangeNotifier {
  final NotificationService _notificationService;
  late Box<Medicine> _medicineBox;

  MedicineProvider(this._notificationService) {
    _medicineBox = Hive.box<Medicine>('medicines');
  }

  // Get all medicines
  List<Medicine> get medicines {
    return _medicineBox.values.toList();
  }

  // Get medicine by ID
  Medicine? getMedicineById(String id) {
    try {
      return _medicineBox.values.firstWhere((medicine) => medicine.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add new medicine
  Future<void> addMedicine(Medicine medicine) async {
    // Generate unique ID if not provided
    final id = medicine.id.isEmpty ? const Uuid().v4() : medicine.id;
    final newMedicine = Medicine(
      id: id,
      name: medicine.name,
      dosage: medicine.dosage,
      dosageUnit: medicine.dosageUnit,
      startDate: medicine.startDate,
      refillDate: medicine.refillDate,
      expiryDate: medicine.expiryDate,
      intervalHours: medicine.intervalHours,
      scheduledTimes: medicine.scheduledTimes,
      takenTimes: medicine.takenTimes,
      notes: medicine.notes,
      isActive: medicine.isActive,
    );

    await _medicineBox.put(id, newMedicine);

    // Schedule notification
    await _notificationService.scheduleNotification(newMedicine);

    notifyListeners();
  }

  // Update existing medicine
  Future<void> updateMedicine(Medicine medicine) async {
    // Cancel existing notifications first
    await _notificationService.cancelNotification(medicine);

    // Update medicine in the box
    await _medicineBox.put(medicine.id, medicine);

    // Reschedule notifications if medicine is active
    if (medicine.isActive) {
      await _notificationService.scheduleNotification(medicine);
    }

    notifyListeners();
  }

  // Delete medicine
  Future<void> deleteMedicine(String id) async {
    final medicine = getMedicineById(id);
    if (medicine != null) {
      // Cancel notifications
      await _notificationService.cancelNotification(medicine);

      // Delete from box
      await _medicineBox.delete(id);

      notifyListeners();
    }
  }

  // Mark medicine as taken
  Future<void> markAsTaken(String id) async {
    final medicine = getMedicineById(id);
    if (medicine != null) {
      // Cancel current notification
      await _notificationService.cancelNotification(medicine);

      // Add current time to taken times
      final now = DateTime.now();
      final takenTimes = [...medicine.takenTimes, now];

      // Update medicine
      final updatedMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        dosage: medicine.dosage,
        dosageUnit: medicine.dosageUnit,
        startDate: medicine.startDate,
        refillDate: medicine.refillDate,
        expiryDate: medicine.expiryDate,
        intervalHours: medicine.intervalHours,
        scheduledTimes: medicine.scheduledTimes,
        takenTimes: takenTimes,
        notes: medicine.notes,
        isActive: medicine.isActive,
        lastUpdated: now,
      );

      await _medicineBox.put(medicine.id, updatedMedicine);

      // Schedule next notification based on interval
      await _notificationService.scheduleNotification(updatedMedicine);

      notifyListeners();
    }
  }

  // Undo marking medicine as taken
  Future<void> undoMarkAsTaken(String id) async {
    final medicine = getMedicineById(id);
    if (medicine != null && medicine.takenTimes.isNotEmpty) {
      // Cancel current notification
      await _notificationService.cancelNotification(medicine);

      // Remove the last taken time
      final takenTimes = [...medicine.takenTimes];
      takenTimes.removeLast();

      // Update medicine
      final updatedMedicine = Medicine(
        id: medicine.id,
        name: medicine.name,
        dosage: medicine.dosage,
        dosageUnit: medicine.dosageUnit,
        startDate: medicine.startDate,
        refillDate: medicine.refillDate,
        expiryDate: medicine.expiryDate,
        intervalHours: medicine.intervalHours,
        scheduledTimes: medicine.scheduledTimes,
        takenTimes: takenTimes,
        notes: medicine.notes,
        isActive: medicine.isActive,
        lastUpdated: DateTime.now(),
      );

      await _medicineBox.put(medicine.id, updatedMedicine);

      // Reschedule notification
      await _notificationService.scheduleNotification(updatedMedicine);

      notifyListeners();
    }
  }

  // Get today's medicines
  List<Medicine> getTodaysMedicines() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    return medicines.where((medicine) {
      if (!medicine.isActive) return false;

      final nextDose = medicine.getNextDoseTime();
      return nextDose.isAfter(today) && nextDose.isBefore(tomorrow);
    }).toList();
  }

  // Get medicines due now or overdue
  List<Medicine> getOverdueMedicines() {
    final now = DateTime.now();

    return medicines.where((medicine) {
      if (!medicine.isActive) return false;

      final nextDose = medicine.getNextDoseTime();
      return nextDose.isBefore(now);
    }).toList();
  }

  // Get upcoming medicines
  List<Medicine> getUpcomingMedicines() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    return medicines.where((medicine) {
      if (!medicine.isActive) return false;

      final nextDose = medicine.getNextDoseTime();
      return nextDose.isAfter(now) && nextDose.isBefore(tomorrow);
    }).toList();
  }

  // Get medicines taken today
  List<Medicine> getTakenMedicines() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    return medicines.where((medicine) {
      return medicine.takenTimes.any((time) => time.isAfter(today) && time.isBefore(tomorrow));
    }).toList();
  }

  // Get medicines that need refills soon
  List<Medicine> getMedicinesNeedingRefill() {
    return medicines.where((medicine) => medicine.isDueForRefill()).toList();
  }

  // Refresh all notifications
  Future<void> refreshAllNotifications() async {
    await _notificationService.cancelAllNotifications();

    for (final medicine in medicines) {
      if (medicine.isActive) {
        await _notificationService.scheduleNotification(medicine);
      }
    }
  }
}