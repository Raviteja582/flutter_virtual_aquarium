import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() => runApp(const FishAquariumApp());

class FishAquariumApp extends StatefulWidget {
  const FishAquariumApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FishAquariumAppState createState() => _FishAquariumAppState();
}

class _FishAquariumAppState extends State<FishAquariumApp>
    with TickerProviderStateMixin {
  List<Fish> fishList = [];
  int fishCount = 0;
  double fishSpeed = 1.0;
  Color fishColor = Colors.blue;
  bool collisionEffectEnabled = true;
  Database? database;

  @override
  void initState() {
    super.initState();
    initDatabase();
    loadSettings();
  }

  Future<void> initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'fish_aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE Settings(id INTEGER PRIMARY KEY, fishCount INTEGER, fishSpeed REAL, fishColor INTEGER)',
        );
      },
      version: 1,
    );
  }

  Future<void> loadSettings() async {
    final List<Map<String, dynamic>> maps = await database!.query('Settings');
    if (maps.isNotEmpty) {
      setState(() {
        fishCount = maps[0]['fishCount'];
        fishSpeed = maps[0]['fishSpeed'];
        fishColor = Color(maps[0]['fishColor']);
        for (int i = 0; i < fishCount; i++) {
          fishList.add(Fish(color: fishColor, speed: fishSpeed, vsync: this));
        }
      });
    }
  }

  Future<void> saveSettings() async {
    await database!.insert(
      'Settings',
      {
        'fishCount': fishList.length,
        'fishSpeed': fishSpeed,
        'fishColor': fishColor.value
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: fishColor, speed: fishSpeed, vsync: this));
      });
    }
  }

  void changeFishColor(Color color) {
    setState(() {
      fishColor = color;
    });
  }

  void changeFishSpeed(double speed) {
    setState(() {
      fishSpeed = speed;
      for (var fish in fishList) {
        fish.updateSpeed(speed);
      }
    });
  }

  void toggleCollisionEffect() {
    setState(() {
      collisionEffectEnabled = !collisionEffectEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Fish Aquarium')),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      color: Colors.blue[100],
                      child: Stack(
                        children:
                            fishList.map((fish) => fish.buildFish()).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Row(
                children: [
                  ElevatedButton(
                      onPressed: addFish, child: const Text('Add Fish')),
                  ElevatedButton(
                      onPressed: toggleCollisionEffect,
                      child: const Text('Toggle Collision')),
                  Slider(
                    value: fishSpeed,
                    min: 0.5,
                    max: 5.0,
                    onChanged: (value) => changeFishSpeed(value),
                    label: 'Speed',
                  ),
                  DropdownButton<Color>(
                    value: fishColor,
                    items: const [
                      DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                      DropdownMenuItem(value: Colors.red, child: Text('Red')),
                      DropdownMenuItem(
                          value: Colors.green, child: Text('Green')),
                    ],
                    onChanged: (value) => changeFishColor(value!),
                  )
                ],
              ),
            ),
            ElevatedButton(
              onPressed: saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class Fish {
  Color color;
  double speed;
  double size = 20;
  late AnimationController controller;
  late Animation<Offset> position;
  Random random = Random();
  bool isColliding = false;
  final TickerProvider vsync;

  Fish({required this.color, required this.speed, required this.vsync}) {
    controller = AnimationController(
      duration: Duration(seconds: (6 ~/ speed)),
      vsync: vsync,
    );
    position = Tween<Offset>(
      begin: Offset(random.nextDouble() * 300, random.nextDouble() * 300),
      end: Offset(random.nextDouble() * 300, random.nextDouble() * 300),
    ).animate(controller)
      ..addListener(() {
        moveFish();
      });
    controller.repeat(reverse: true);
  }

  void updateSpeed(double newSpeed) {
    controller.duration = Duration(seconds: (6 ~/ newSpeed));
  }

  Widget buildFish() {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Positioned(
          left: position.value.dx,
          top: position.value.dy,
          child: Transform.scale(
            scale: size / 20,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  void moveFish() {
    if (position.value.dx >= 300 ||
        position.value.dx <= 0 ||
        position.value.dy >= 300 ||
        position.value.dy <= 0) {
      changeDirection();
    }
  }

  void changeDirection() {
    position = Tween<Offset>(
      begin: Offset(random.nextDouble() * 300, random.nextDouble() * 300),
      end: Offset(random.nextDouble() * 300, random.nextDouble() * 300),
    ).animate(controller);
  }
}
