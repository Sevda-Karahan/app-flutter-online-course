import 'dart:async';
import 'package:online_course/src/JSON/users.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;
  String user = '''
   CREATE TABLE users (
   usrId INTEGER PRIMARY KEY AUTOINCREMENT,
   fullName TEXT,
   email TEXT,
   phoneNumber TEXT,
   address TEXT,
   usrName TEXT UNIQUE,
   usrPassword TEXT
   )
   ''';
  String payments = '''
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId INTEGER,
  courseId INTEGER,
  paymentMethod TEXT,
  paymentDate TEXT
)
''';

  String admin = '''
   CREATE TABLE admins (
   adminId INTEGER PRIMARY KEY AUTOINCREMENT,
   usrName TEXT UNIQUE,
   usrPassword TEXT
   )
   ''';

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'instructors_database.db');
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute(
      'CREATE TABLE instructors(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, homePhone TEXT, cellPhone TEXT, address TEXT, email TEXT)',
    );

    await db.execute(
      'CREATE TABLE lessons(id INTEGER PRIMARY KEY AUTOINCREMENT, instructorId INTEGER, name TEXT, price REAL, isWeekday INTEGER)',
    );

    await db.execute(
      'CREATE TABLE hours(id INTEGER PRIMARY KEY AUTOINCREMENT, instructorId INTEGER, hour INTEGER)',
    );
    await db.execute(
      'CREATE TABLE courses(id INTEGER PRIMARY KEY AUTOINCREMENT, instructorId INTEGER, name TEXT, description TEXT, price REAL, image TEXT, startDate TEXT, endDate TEXT, lessonIds TEXT, craftDays TEXT)',
    );
    await db.execute(user); // users tablosunu oluştur
    await db.execute(admin); // admins tablosunu oluştur
    await db.execute(payments); // payments tablosunu oluştur
    await _insertAdmin(db, 'admin', 'admin');
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    try {
      // Veritabanına erişim sağla
      Database db = await instance.database;

      // Tüm ödemeleri al ve geri döndür
      return await db.query('payments');
    } catch (e) {
      // Hata durumunda boş bir liste döndür
      print('Error getting payments: $e');
      return [];
    }
  }

  Future<int> _insertAdmin(
      Database db, String userName, String password) async {
    Map<String, dynamic> admin = {
      'usrName': userName,
      'usrPassword': password,
    };
    return await db.insert('admins', admin);
  }

  Future<void> printPayments() async {
    try {
      // Veritabanından ödemeleri al
      List<Map<String, dynamic>> payments = await getPayments();

      // Ödemeleri yazdır
      for (var payment in payments) {
        print('Payment ID: ${payment['id']}');
        print('User ID: ${payment['userId']}');
        print('Course ID: ${payment['courseId']}');
        print('Payment Method: ${payment['paymentMethod']}');
        print('Payment Date: ${payment['paymentDate']}');
        print('---------------------------------');
      }
    } catch (e) {
      print('Error printing payments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLessonNamesByCourseId(
      int courseId) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> lessonList = [];

    // İlgili kursun bilgisini al
    Map<String, dynamic>? course = await getCourseById(courseId);

    if (course != null) {
      // Kursun ders ID'lerini ayırarak bir listeye dönüştür
      List<String> lessonIds = (course['lessonIds'] as String).split(',');
      print('Parsed Lesson IDs: $lessonIds');

      // Her bir ders için ders bilgisini al ve listeye ekle
      for (String lessonId in lessonIds) {
        int id = int.parse(lessonId);
        List<Map<String, dynamic>> lessons = await db.query(
          'lessons',
          where: 'id = ?',
          whereArgs: [id],
        );

        // Ders bulunduysa listeye ekle
        if (lessons.isNotEmpty) {
          lessonList.add(lessons.first);
          print(
              'Found lesson: ${lessons.first}'); // Debug: Bulunan ders bilgisi
        } else {
          print('No lesson found for ID: $id'); // Debug: Bulunamayan ders
        }
      }
    }

    return lessonList;
  }

  Future<int> insertInstructor(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('instructors', row);
  }

  // Yeni metod: Tüm kursları al
  Future<List<Map<String, dynamic>>> getCourses() async {
    Database db = await instance.database;
    return await db.query('courses');
  }

  Future<void> printAllLessons() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> lessons = await db.query('lessons');

    for (var lesson in lessons) {
      print('Lesson: $lesson');
    }
  }

  Future<int> insertLesson(Map<String, dynamic> row, bool isWeekday) async {
    Database db = await instance.database;
    row['isWeekday'] = isWeekday ? 1 : 0; // 1: hafta içi, 0: hafta sonu
    return await db.insert('lessons', row);
  }

  Future<List<Map<String, dynamic>>> getInstructors() async {
    Database db = await instance.database;
    return await db.query('instructors');
  }

  Future<List<Map<String, dynamic>>> getLessons() async {
    Database db = await instance.database;
    return await db.query('lessons');
  }

  Future<int> deleteInstructor(int id) async {
    Database db = await instance.database;
    await db.delete('hours', where: 'instructorId = ?', whereArgs: [id]);
    await db.delete('lessons', where: 'instructorId = ?', whereArgs: [id]);
    return await db.delete('instructors', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getInstructorById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'instructors',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getHoursByInstructorId(
      int instructorId) async {
    Database db = await instance.database;
    return await db
        .query('hours', where: 'instructorId = ?', whereArgs: [instructorId]);
  }

  Future<int> insertCourse(Map<String, dynamic> course) async {
    Database db = await instance.database;
    return await db.insert('courses', course);
  }

  Future<List<Map<String, dynamic>>> getLessonsByInstructorId(
      int instructorId) async {
    Database db = await instance.database;
    return await db
        .query('lessons', where: 'instructorId = ?', whereArgs: [instructorId]);
  }

  Future<List<Map<String, dynamic>>> getLessonsByInstructor(
      int instructorId) async {
    return await DatabaseHelper.instance.getLessonsByInstructorId(instructorId);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    Database db = await instance.database;
    return await db.query('users');
  }

  // DatabaseHelper sınıfına saatleri eklemek için yeni bir fonksiyon ekleyin
  Future<int> insertHours(int instructorId, List<int> hours) async {
    Database db = await instance.database;
    for (int hour in hours) {
      await db.insert('hours', {'instructorId': instructorId, 'hour': hour});
    }
    // İşlem başarıyla tamamlandığında, burada bir değer döndürebilirsiniz.
    return 1; // Örneğin, eklenecek saat sayısını döndürüyoruz.
  }

  Future<String?> getInstructorNameById(int id) async {
    try {
      Database db = await instance.database;
      List<Map<String, dynamic>> result = await db.query(
        'instructors',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return result.first['name'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching instructor name: $e');
      return null;
    }
  }

  Future<int> updateInstructor(Map<String, dynamic> updatedInstructor) async {
    Database db = await instance.database;
    int id = updatedInstructor['id'];

    // Önceki saat ve ders bilgilerini al
    List<Map<String, dynamic>> oldHours = await getHoursByInstructorId(id);
    List<Map<String, dynamic>> oldLessons = await getLessonsByInstructorId(id);

    // hours ve lessons alanlarını uygun formata dönüştür
    List<int> hours = updatedInstructor['hours'].cast<int>();
    List<String> lessons = updatedInstructor['lessons'].cast<String>();
    Map<String, double> lessonPrices = updatedInstructor['lessonPrices'];

    // Transaksyon kullanarak güncelleme işlemlerini gerçekleştir
    return await db.transaction((txn) async {
      // Önceki saat ve ders bilgilerini sil
      await txn.delete('hours', where: 'instructorId = ?', whereArgs: [id]);
      await txn.delete('lessons', where: 'instructorId = ?', whereArgs: [id]);

      // Yeni saat bilgilerini ekle
      for (int hour in hours) {
        await txn.insert('hours', {'instructorId': id, 'hour': hour});
      }

      // Yeni ders bilgilerini ekle
      for (String lesson in lessons) {
        await txn.insert('lessons', {
          'instructorId': id,
          'name': lesson,
          'price': lessonPrices[lesson],
        });
      }

      // Öğretmen bilgilerini güncelle
      return await txn.update(
        'instructors',
        {
          'id': id,
          'name': updatedInstructor['name'],
          'homePhone': updatedInstructor['homePhone'],
          'cellPhone': updatedInstructor['cellPhone'],
          'address': updatedInstructor['address'],
          'email': updatedInstructor['email'],
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  //Authentication
  Future<bool> authenticate(Users usr) async {
    Database db = await instance.database;
    var result = await db.rawQuery(
        "select * from users where usrName = '${usr.usrName}' AND usrPassword = '${usr.password}' ");
    if (result.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  //Sign up
  Future<int> createUser(Users usr) async {
    Database db = await instance.database;
    return db.insert("users", usr.toMap());
  }

  //Get current User details
  Future<Users?> getUser(String usrName) async {
    Database db = await instance.database;
    var res =
        await db.query("users", where: "usrName = ?", whereArgs: [usrName]);
    return res.isNotEmpty ? Users.fromMap(res.first) : null;
  }

  Future<int> deleteCourse(int id) async {
    Database db = await instance.database;

    // Delete the course from the courses table
    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // Get course by ID
  Future<Map<String, dynamic>?> getCourseById(int id) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  // Update course
  Future<int> updateCourse(Map<String, dynamic> course) async {
    Database db = await instance.database;
    int id = course['id'];
    return await db.update(
      'courses',
      course,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>> searchCoursesByBudgetAndCategories({
    required List<int> selectedCategories,
    required double budget,
  }) async {
    Database db = await instance.database;

    // Kursları filtrelemek için kullanılacak sorgu koşulu
    String whereClause = '';

    // Seçilen el işi kategorilerini ekleyin
    if (selectedCategories.isNotEmpty) {
      // Seçilen kategorilerin herhangi biriyle eşleşen bir deseni arayın
      for (int categoryId in selectedCategories) {
        whereClause += 'lessonIds LIKE \'%$categoryId%\' OR ';
      }
    }

    // Bütçeye göre sorgu koşulunu güncelleyin
    if (budget > 0) {
      whereClause += 'price >= $budget AND ';
    }

    // Sorgu koşulunu kontrol edin ve gerektiğinde son karakteri silin
    if (whereClause.isNotEmpty) {
      whereClause = 'WHERE ${whereClause.substring(0, whereClause.length - 4)}';
    }

    // Kursları arayın ve sonucu döndürün
    return await db.rawQuery('SELECT * FROM courses $whereClause');
  }

  //Authentication for admin
  Future<bool> authenticateAdmin(String usrName, String password) async {
    Database db = await instance.database;
    var result = await db.rawQuery(
      "SELECT * FROM admins WHERE usrName = ? AND usrPassword = ?",
      [usrName, password],
    );
    return result.isNotEmpty;
  }

  Future<Users?> getUserById(int userId) async {
    try {
      Database db = await instance.database;
      List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'usrId = ?',
        whereArgs: [userId],
      );
      if (result.isNotEmpty) {
        return Users.fromMap(result.first);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }
}
