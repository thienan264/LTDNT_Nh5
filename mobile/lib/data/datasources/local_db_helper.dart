import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cart_item_model.dart';
import '../models/category_model.dart';
import '../models/device_model.dart';

class LocalDbHelper {
  static final LocalDbHelper instance = LocalDbHelper._internal();
  LocalDbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'equipment_rental_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Table for persistent offline rental cart items
        await db.execute('''
          CREATE TABLE rental_cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            device_id INTEGER UNIQUE NOT NULL,
            device_name TEXT NOT NULL,
            serial_number TEXT NOT NULL,
            category_name TEXT NOT NULL,
            category_id INTEGER,
            daily_rate REAL NOT NULL,
            rental_days INTEGER NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            image_url TEXT,
            qr_code TEXT,
            unit_name TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        // 2. Table for offline cached categories
        await db.execute('''
          CREATE TABLE cached_categories (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            image_url TEXT,
            device_count INTEGER DEFAULT 0,
            updated_at TEXT NOT NULL
          )
        ''');

        // 3. Table for offline cached devices
        await db.execute('''
          CREATE TABLE cached_devices (
            id INTEGER PRIMARY KEY,
            serial_number TEXT NOT NULL,
            name TEXT NOT NULL,
            category_name TEXT NOT NULL,
            category_id INTEGER,
            status TEXT NOT NULL,
            rental_price_per_day REAL NOT NULL,
            qr_code TEXT,
            image_url TEXT,
            unit_name TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  // ==================== CART CRUD (SQLITE) ====================

  Future<List<CartItemModel>> getCartItems() async {
    try {
      final db = await database;
      final maps = await db.query('rental_cart_items', orderBy: 'id ASC');

      return maps.map((row) {
        final device = DeviceModel(
          id: row['device_id'] as int,
          serialNumber: row['serial_number'] as String,
          name: row['device_name'] as String,
          categoryName: row['category_name'] as String,
          categoryId: row['category_id'] as int?,
          status: DeviceStatus.available,
          rentalPricePerDay: (row['daily_rate'] as num).toDouble(),
          qrCode: row['qr_code'] as String? ?? '',
          imageUrl: row['image_url'] as String?,
          currentUnitName: row['unit_name'] as String?,
        );

        return CartItemModel(
          device: device,
          rentalDays: row['rental_days'] as int,
          quantity: row['quantity'] as int? ?? 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('[SQLite] Error loading cart: $e');
      return [];
    }
  }

  Future<void> saveCartItem(DeviceModel device, int rentalDays) async {
    try {
      final db = await database;
      await db.insert('rental_cart_items', {
        'device_id': device.id,
        'device_name': device.name,
        'serial_number': device.serialNumber,
        'category_name': device.categoryName,
        'category_id': device.categoryId,
        'daily_rate': device.rentalPricePerDay,
        'rental_days': rentalDays,
        'quantity': 1,
        'image_url': device.imageUrl,
        'qr_code': device.qrCode,
        'unit_name': device.currentUnitName,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('[SQLite] Error saving cart item: $e');
    }
  }

  Future<void> updateCartDays(int deviceId, int days) async {
    try {
      final db = await database;
      await db.update(
        'rental_cart_items',
        {'rental_days': days},
        where: 'device_id = ?',
        whereArgs: [deviceId],
      );
    } catch (e) {
      debugPrint('[SQLite] Error updating cart days: $e');
    }
  }

  Future<void> removeCartItem(int deviceId) async {
    try {
      final db = await database;
      await db.delete(
        'rental_cart_items',
        where: 'device_id = ?',
        whereArgs: [deviceId],
      );
    } catch (e) {
      debugPrint('[SQLite] Error removing cart item: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final db = await database;
      await db.delete('rental_cart_items');
    } catch (e) {
      debugPrint('[SQLite] Error clearing cart: $e');
    }
  }

  // ==================== CATEGORIES CACHE (SQLITE) ====================

  Future<void> cacheCategories(List<CategoryModel> categories) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final cat in categories) {
        batch.insert('cached_categories', {
          'id': cat.id,
          'name': cat.name,
          'description': cat.description,
          'image_url': cat.imageUrl,
          'device_count': cat.deviceCount,
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[SQLite] Error caching categories: $e');
    }
  }

  Future<List<CategoryModel>> getCachedCategories() async {
    try {
      final db = await database;
      final maps = await db.query('cached_categories', orderBy: 'id ASC');
      return maps
          .map(
            (row) => CategoryModel(
              id: row['id'] as int,
              name: row['name'] as String,
              description: row['description'] as String? ?? '',
              imageUrl: row['image_url'] as String? ?? '',
              deviceCount: row['device_count'] as int? ?? 0,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[SQLite] Error reading cached categories: $e');
      return [];
    }
  }

  // ==================== DEVICES CACHE (SQLITE) ====================

  Future<void> cacheDevices(List<DeviceModel> devices) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (final dev in devices) {
        batch.insert('cached_devices', {
          'id': dev.id,
          'serial_number': dev.serialNumber,
          'name': dev.name,
          'category_name': dev.categoryName,
          'category_id': dev.categoryId,
          'status': dev.status.name.toUpperCase(),
          'rental_price_per_day': dev.rentalPricePerDay,
          'qr_code': dev.qrCode,
          'image_url': dev.imageUrl,
          'unit_name': dev.currentUnitName,
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      debugPrint('[SQLite] Error caching devices: $e');
    }
  }

  Future<List<DeviceModel>> getCachedDevices() async {
    try {
      final db = await database;
      final maps = await db.query('cached_devices', orderBy: 'id ASC');
      return maps
          .map(
            (row) => DeviceModel(
              id: row['id'] as int,
              serialNumber: row['serial_number'] as String,
              name: row['name'] as String,
              categoryName: row['category_name'] as String,
              categoryId: row['category_id'] as int?,
              status: DeviceStatus.fromString(
                row['status'] as String? ?? 'AVAILABLE',
              ),
              rentalPricePerDay: (row['rental_price_per_day'] as num)
                  .toDouble(),
              qrCode: row['qr_code'] as String? ?? '',
              imageUrl: row['image_url'] as String?,
              currentUnitName: row['unit_name'] as String?,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('[SQLite] Error reading cached devices: $e');
      return [];
    }
  }
}
