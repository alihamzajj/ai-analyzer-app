import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../ai_analysis/models/analysis_report.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';

/// Local on-device storage service for reports and cached digests.
/// Uses SharedPreferences and FlutterSecureStorage with encrypted keys.
class LocalReportStorage {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Loads all saved reports from local on-device storage.
  static Future<List<AnalysisReport>> getAllReports() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(AppConstants.keySavedReports) ?? [];

      final List<AnalysisReport> reports = [];
      for (final jsonStr in rawList) {
        try {
          final map = jsonDecode(jsonStr);
          reports.add(AnalysisReport.fromJson(map));
        } catch (_) {
          // Skip corrupt individual items without crashing the list
        }
      }

      // Sort newest first
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports;
    } catch (e) {
      throw StorageException('Failed to load local reports: $e', details: e);
    }
  }

  /// Saves or updates a report on the device.
  static Future<void> saveReport(AnalysisReport report) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(AppConstants.keySavedReports) ?? [];

      // Remove existing version of same report ID if updating
      final updatedList = currentList.where((str) {
        try {
          final map = jsonDecode(str);
          return map['id'] != report.id;
        } catch (_) {
          return true;
        }
      }).toList();

      updatedList.insert(0, jsonEncode(report.toJson()));
      await prefs.setStringList(AppConstants.keySavedReports, updatedList);
    } catch (e) {
      throw StorageException('Failed to save report locally: $e', details: e);
    }
  }

  /// Deletes a specific report by ID.
  static Future<void> deleteReport(String reportId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = prefs.getStringList(AppConstants.keySavedReports) ?? [];

      final updatedList = currentList.where((str) {
        try {
          final map = jsonDecode(str);
          return map['id'] != reportId;
        } catch (_) {
          return true;
        }
      }).toList();

      await prefs.setStringList(AppConstants.keySavedReports, updatedList);
    } catch (e) {
      throw StorageException('Failed to delete report $reportId: $e', details: e);
    }
  }

  /// One-tap "Delete All Data" action.
  /// Removes all saved reports, cached digests, preferences, and secure keys.
  static Future<void> deleteAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keySavedReports);
      await prefs.remove(AppConstants.keyDigestCache);
      await prefs.remove(AppConstants.keyAnonymousUserId);

      // Wipe secure storage
      await _secureStorage.deleteAll();
    } catch (e) {
      throw StorageException('Failed to complete delete all data: $e', details: e);
    }
  }
}
