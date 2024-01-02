// lib/main.dart
import 'package:flutter/material.dart';
import 'package:lab_6_sqlit/model/todo_model.dart';

import 'package:lab_6_sqlit/service/to_do_service.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SQFlite Example',
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TextEditingController _titleController = TextEditingController();
  int? _editingTodoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List'),
      ),
      body: FutureBuilder<List<Todo>>(
        future: _getTodos(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Todo> todos = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(todos[index].title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _startEditingTodo(todos[index]);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteTodo(todos[index].id);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _editingTodoId != null ? _buildEditTodoForm() : _buildAddTodoForm(),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _buildAddTodoForm() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: 'New Todo'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _addTodo();
          },
          child: Text('Add'),
        ),
      ],
    );
  }

  Widget _buildEditTodoForm() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: 'Edit Todo'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _updateTodo();
          },
          child: Text('Update'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _cancelEditing();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

  Future<List<Todo>> _getTodos() async {
    final Database db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('todos');

    return List.generate(maps.length, (index) {
      return Todo.fromMap(maps[index]);
    });
  }

  Future<void> _addTodo() async {
    final String title = _titleController.text.trim();

    if (title.isNotEmpty) {
      final Database db = await DatabaseHelper.instance.database;

      await db.insert(
        'todos',
        Todo(
          id: DateTime.now().millisecondsSinceEpoch,
          title: title,
          isDone: false,
        ).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Clear the text field after adding the todo
      _titleController.clear();

      // Refresh the list of todos
      setState(() {});
    }
  }

  void _startEditingTodo(Todo todo) {
    _titleController.text = todo.title;
    _editingTodoId = todo.id;

    // Refresh the UI to show the edit form
    setState(() {});
  }

  Future<void> _updateTodo() async {
    final String title = _titleController.text.trim();

    if (title.isNotEmpty && _editingTodoId != null) {
      final Database db = await DatabaseHelper.instance.database;

      await db.update(
        'todos',
        Todo(
          id: _editingTodoId!,
          title: title,
          isDone: false, // You may want to handle this differently based on your requirements
        ).toMap(),
        where: 'id = ?',
        whereArgs: [_editingTodoId],
      );

      // Clear the text field and reset the editing state
      _titleController.clear();
      _editingTodoId = null;

      // Refresh the list of todos
      setState(() {});
    }
  }

  void _cancelEditing() {
    // Clear the text field and reset the editing state
    _titleController.clear();
    _editingTodoId = null;

    // Refresh the UI to hide the edit form
    setState(() {});
  }

  Future<void> _deleteTodo(int todoId) async {
    final Database db = await DatabaseHelper.instance.database;

    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [todoId],
    );

    // Refresh the list of todos
    setState(() {});
  }
}
