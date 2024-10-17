import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'bus_station.db');
    return await openDatabase(path, version: 1);
  }

  // 메인에서 호출되는 favorite 테이블 생성
  Future<void> createFavoriteTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorite(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        station_no TEXT,
        city_code INTEGER,
        routeno TEXT,
        routeid TEXT
      )
    ''');
    print('favorite 테이블 생성 완료');
  }

  Future<void> insertFavorite(String stationNo, int cityCode, String routeno, String routeid) async {
    final db = await database;
    await db.insert('favorite', {
      'station_no': stationNo,
      'city_code': cityCode,
      'routeno': routeno,
      'routeid': routeid,
    });
    print('즐겨찾기에 추가됨: $routeno');
  }
  
  // 즐겨찾기 삭제 메서드 추가
  Future<void> deleteFavorite(int id) async {
    final db = await database;
    await db.delete(
      'favorite',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('즐겨찾기 삭제 완료: id = $id');
  }

  // mapPage에서 호출되는 station 테이블 생성 및 CSV 데이터 삽입
  Future<void> createStationTableAndInsertData() async {
    final db = await database;

    // station 테이블 생성
    await db.execute('''
      CREATE TABLE IF NOT EXISTS station(
        station_no TEXT PRIMARY KEY,
        station_name TEXT,
        latitude REAL,
        longitude REAL,
        collection_date TEXT,
        mobile_short_number TEXT,
        city_code TEXT,
        city_name TEXT,
        management_city_name TEXT
      )
    ''');
    print('station 테이블 생성 완료');

    // CSV 데이터 삽입
    await _importCSVtoDB(db);
  }

  Future<void> _importCSVtoDB(Database db) async {
    print('CSV 데이터 삽입 작업 시작');
    try {
      final rawData = await rootBundle.loadString('assets/stations.csv');
      print('CSV 데이터 로딩에 성공했습니다.');
      List<List<dynamic>> csvData = const CsvToListConverter().convert(rawData);
      print('CSV 데이터 변환에 성공했습니다. 삽입 작업을 시작합니다.');

      const batchSize = 5000; // 한 번에 삽입할 데이터 크기
      for (int i = 1; i < csvData.length; i += batchSize) {
        List<List<dynamic>> batch = csvData.sublist(i, i + batchSize > csvData.length ? csvData.length : i + batchSize);

        await db.transaction((txn) async {
          for (List<dynamic> row in batch) {
            await txn.insert('station', {
              'station_no': row[0],
              'station_name': row[1],
              'latitude': row[2],
              'longitude': row[3],
              'collection_date': row[4],
              'mobile_short_number': row[5],
              'city_code': row[6],
              'city_name': row[7],
              'management_city_name': row[8],
            });
          }
        });
        print('CSV 데이터 ${i}-${i + batchSize}행까지 삽입 완료.');
      }

      print('CSV 데이터를 성공적으로 station 테이블에 삽입했습니다.');
    } catch (e) {
      print('CSV 처리 오류: $e');
    }
  }

}


