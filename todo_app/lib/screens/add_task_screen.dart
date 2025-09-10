import 'package:flutter/material.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../Models/todo.dart';
import '../main.dart'; // للوصول إلى flutterLocalNotificationsPlugin

class AddTaskScreen extends StatefulWidget {
  final Function(Todo) onAdd;
  final Todo? existingTodo; // لإرسال المهمة الموجودة للتعديل

  const AddTaskScreen({super.key, required this.onAdd, this.existingTodo});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  late TextEditingController _controller;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
        text: widget.existingTodo != null ? widget.existingTodo!.title : '');
    if (widget.existingTodo != null && widget.existingTodo!.time != null) {
      final parts = widget.existingTodo!.time!.split(':');
      if (parts.length == 2) {
        int hour = int.tryParse(parts[0]) ?? 0;
        int minute = int.tryParse(parts[1]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  /// دالة جدولة الإشعار
  Future<int?> _scheduleNotification(Todo todo) async {
    if (_selectedTime == null) return null;

    try {
      final now = tz.TZDateTime.now(tz.local);
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (scheduledDate.isBefore(now.add(const Duration(seconds: 30)))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // إنشاء معرف جديد للإشعار
      int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        'ToDo Reminder',
        todo.title,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'todo_channel_id',
            'ToDo Notifications',
            channelDescription: 'Channel for ToDo reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      return notificationId;
    } catch (e) {
      debugPrint('Notification error: $e');
      return null;
    }
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask() async {
    if (_controller.text.trim().isEmpty) return;

    Todo newTodo = Todo(
      title: _controller.text.trim(),
      isDone: widget.existingTodo?.isDone ?? false,
      time: _selectedTime?.format(context),
    );

    // إذا كانت مهمة موجودة (تعديل)
    if (widget.existingTodo != null) {
      // إلغاء الإشعار القديم
      if (widget.existingTodo!.notificationId != null) {
        flutterLocalNotificationsPlugin.cancel(widget.existingTodo!.notificationId!);
      }

      // جدولة إشعار جديد وتخزين معرفه
      int? newId = await _scheduleNotification(newTodo);
      newTodo.notificationId = newId;

      // تحديث المهمة الأصلية
      widget.existingTodo!.title = newTodo.title;
      widget.existingTodo!.time = newTodo.time;
      widget.existingTodo!.notificationId = newTodo.notificationId;
      widget.existingTodo!.save();
    } else {
      // مهمة جديدة
      int? newId = await _scheduleNotification(newTodo);
      newTodo.notificationId = newId;
      widget.onAdd(newTodo);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTodo != null;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Text(
          isEditing ? "Edit Task" : "Add New Task",
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Task Title",
                hintText: "Enter your task here",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedTime == null
                        ? "No Reminder Time Chosen"
                        : "Reminder at: ${_selectedTime!.format(context)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                  onPressed: _pickTime,
                  child: const Text("Pick Time"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _saveTask,
                child: Text(
                  isEditing ? "Save Changes" : "Save Task",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
