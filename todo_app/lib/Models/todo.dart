import 'package:hive/hive.dart';

part 'todo.g.dart';  // ملف مولد تلقائيًا يحتوي على الكود المساعد لـ Hive

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isDone;

  @HiveField(2)
  String? time; // لتخزين وقت المهمة

  @HiveField(3)
  int? notificationId; // لتخزين معرف الإشعار المرتبط بالمهمة

  Todo({
    required this.title,
    this.isDone = false,
    this.time,
    this.notificationId,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isDone': isDone ? 1 : 0,
      'time': time,
      'notificationId': notificationId,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      title: map['title'],
      isDone: map['isDone'] == 1,
      time: map['time'],
      notificationId: map['notificationId'],
    );
  }
}
