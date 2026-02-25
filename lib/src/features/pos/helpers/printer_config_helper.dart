import 'dart:convert';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/service/printer_service.dart';

/// Saves/loads printer settings so they persist across app restarts
class PrinterConfigHelper {
  static const String _printerConfigsKey = 'printer_configurations';
  static const String _lastSyncKey = 'printer_configs_last_sync';

  /// Save printer configurations to local storage
  static Future<bool> savePrinterConfigs(List<PrinterConfig> configs) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final configsJson = configs.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(configsJson);

      final success = await prefs.setString(_printerConfigsKey, jsonString);

      if (success) {
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        AppLogger.log('Saved ${configs.length} printer configurations');
      }

      return success;
    } catch (e) {
      AppLogger.log('Error saving printer configs: $e');
      return false;
    }
  }

  /// Load printer configurations from local storage
  static Future<List<PrinterConfig>> loadPrinterConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = prefs.getString(_printerConfigsKey);

      if (jsonString == null || jsonString.isEmpty) {
        AppLogger.log('No saved printer configurations found');
        return [];
      }

      final List<dynamic> configsJson = jsonDecode(jsonString);
      final configs = configsJson
          .map((json) => PrinterConfig.fromJson(json))
          .toList();

      AppLogger.log('Loaded ${configs.length} printer configurations');
      return configs;
    } catch (e) {
      AppLogger.log('Error loading printer configs: $e');
      return [];
    }
  }

  /// Clear all saved printer configurations
  static Future<bool> clearPrinterConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_printerConfigsKey);

      if (success) {
        await prefs.remove(_lastSyncKey);
        AppLogger.log('Cleared all printer configurations');
      }

      return success;
    } catch (e) {
      AppLogger.log('Error clearing printer configs: $e');
      return false;
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSyncKey);

      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      AppLogger.log('Error getting last sync time: $e');
    }
    return null;
  }

  /// Sync current printer service state to storage
  static Future<bool> syncPrinterService(PrinterService service) async {
    return await savePrinterConfigs(service.printers);
  }

  /// Load configs into printer service
  static Future<void> loadIntoPrinterService(PrinterService service) async {
    final configs = await loadPrinterConfigs();

    service.clearPrinters();

    for (final config in configs) {
      service.addPrinter(config);
    }

    AppLogger.log('Loaded ${configs.length} printers into service');
  }

  /// Export printer configurations as JSON string (for backup/sharing)
  static Future<String?> exportConfigs() async {
    try {
      final configs = await loadPrinterConfigs();

      if (configs.isEmpty) {
        return null;
      }

      final exportData = {
        'version': '1.0',
        'exported_at': DateTime.now().toIso8601String(),
        'printer_count': configs.length,
        'printers': configs.map((c) => c.toJson()).toList(),
      };

      return jsonEncode(exportData);
    } catch (e) {
      AppLogger.log('Error exporting configs: $e');
      return null;
    }
  }

  /// Import printer configurations from JSON string
  static Future<bool> importConfigs(String jsonString) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonString);

      if (!importData.containsKey('printers')) {
        AppLogger.log('Invalid import format - missing printers key');
        return false;
      }

      final List<dynamic> printersJson = importData['printers'];
      final configs = printersJson
          .map((json) => PrinterConfig.fromJson(json))
          .toList();

      final success = await savePrinterConfigs(configs);

      if (success) {
        AppLogger.log('Imported ${configs.length} printer configurations');
      }

      return success;
    } catch (e) {
      AppLogger.log('Error importing configs: $e');
      return false;
    }
  }

  /// Get summary of saved printers by connection type
  static Future<Map<String, int>> getPrinterSummary() async {
    final configs = await loadPrinterConfigs();

    final summary = <String, int>{
      'network': 0,
      'bluetooth': 0,
      'usb': 0,
      'serial': 0,
      'kitchen': 0,
      'receipt': 0,
      'total': configs.length,
    };

    for (final config in configs) {
      switch (config.connectionType) {
        case PrinterConnectionType.network:
          summary['network'] = (summary['network'] ?? 0) + 1;
          break;
        case PrinterConnectionType.bluetooth:
          summary['bluetooth'] = (summary['bluetooth'] ?? 0) + 1;
          break;
        case PrinterConnectionType.usb:
          summary['usb'] = (summary['usb'] ?? 0) + 1;
          break;
        case PrinterConnectionType.serial:
          summary['serial'] = (summary['serial'] ?? 0) + 1;
          break;
      }

      if (config.isKitchenPrinter) {
        summary['kitchen'] = (summary['kitchen'] ?? 0) + 1;
      }
      if (config.isReceiptPrinter) {
        summary['receipt'] = (summary['receipt'] ?? 0) + 1;
      }
    }

    return summary;
  }
}

/// Extension to add cache methods to your existing AuthCacheHelper
/// Add this to your AuthCacheHelper class or create a new cache helper
extension PrinterCacheExtension on AuthCacheHelper {
  /// Save printer configurations
  Future<bool> savePrinterConfigs(List<PrinterConfig> configs) async {
    return await PrinterConfigHelper.savePrinterConfigs(configs);
  }

  /// Load printer configurations
  Future<List<PrinterConfig>> getPrinterConfigs() async {
    return await PrinterConfigHelper.loadPrinterConfigs();
  }

  /// Clear printer configurations
  Future<bool> clearPrinterConfigs() async {
    return await PrinterConfigHelper.clearPrinterConfigs();
  }
}
