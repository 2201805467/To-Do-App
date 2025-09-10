import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../Models/todo.dart';
import 'add_task_screen.dart';
import '../main.dart'; // للوصول إلى flutterLocalNotificationsPlugin

class HomeScreen extends StatefulWidget {
  final Box<Todo> todoBox;

  const HomeScreen({super.key, required this.todoBox});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Todo> todoBox;

  @override
  void initState() {
    super.initState();
    todoBox = widget.todoBox;
  }

  // تغيير حالة المهمة (تم الانتهاء أو لا)
  void toggleTask(int index) {
    final todo = todoBox.getAt(index);
    if (todo != null) {
      todo.isDone = !todo.isDone;
      todo.save();
    }
  }

  // حذف المهمة مع حذف الإشعار
  void deleteTask(int index) {
    final todo = todoBox.getAt(index);
    if (todo != null) {
      if (todo.notificationId != null) {
        flutterLocalNotificationsPlugin.cancel(todo.notificationId!);
      }
      todo.delete();
    }
  }

  // فتح شاشة إضافة أو تعديل المهمة
  void openTaskScreen({Todo? todo}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          onAdd: (newTodo) {
            if (todo != null) {
              // تعديل المهمة الحالية
              todo.title = newTodo.title;
              todo.time = newTodo.time;
              todo.save();

              // إعادة جدولة الإشعار إذا كان موجودًا
              if (todo.notificationId != null) {
                flutterLocalNotificationsPlugin.cancel(todo.notificationId!);
                // هنا يمكن استدعاء دالة جدولة الإشعار من AddTaskScreen
              }
            } else {
              // إضافة مهمة جديدة
              todoBox.add(newTodo);
            }
          },
          existingTodo: todo, // تمرير المهمة لتعبئة الحقول
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text(
          "Tasks List",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: todoBox.listenable(),
        builder: (context, Box<Todo> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text(
                "No tasks yet. Add one!",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: box.length,
            itemBuilder: (context, index) {
              final todo = box.getAt(index)!;
              return Card(
                color: Colors.blueAccent,
                child: ListTile(
                  onTap: () => openTaskScreen(todo: todo), // فتح للتعديل عند الضغط على المهمة
                  leading: Checkbox(
                    value: todo.isDone,
                    onChanged: (value) => toggleTask(index),
                    activeColor: Colors.white,
                    checkColor: Colors.blueAccent,
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isDone ? TextDecoration.lineThrough : null,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (todo.time != null && todo.time!.isNotEmpty)
                        Text(
                          "⏰ ${todo.time}",
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => openTaskScreen(todo: todo), // زر تعديل
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteTask(index),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => openTaskScreen(), // إضافة مهمة جديدة
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
