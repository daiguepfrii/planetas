import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD Planetas',
      home: PlanetaListPage(),
    );
  }
}

class Planeta {
  int? id;
  String nome;
  double distanciaSol;
  double tamanho;
  String? apelido;

  Planeta({this.id, required this.nome, required this.distanciaSol, required this.tamanho, this.apelido});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'distancia_sol': distanciaSol,
      'tamanho': tamanho,
      'apelido': apelido,
    };
  }

  factory Planeta.fromMap(Map<String, dynamic> map) {
    return Planeta(
      id: map['id'],
      nome: map['nome'],
      distanciaSol: map['distancia_sol'],
      tamanho: map['tamanho'],
      apelido: map['apelido'],
    );
  }
}

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  late Database _db;

  DBHelper._internal();

  Future<void> initDB() async {
    String path = join(await getDatabasesPath(), 'planetas.db');
    _db = await openDatabase(path, version: 1, onCreate: _createDB);
  }

  void _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planetas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        distancia_sol REAL,
        tamanho REAL,
        apelido TEXT
      )
    ''');
  }

  Future<int> addPlaneta(Planeta planeta) async {
    return await _db.insert('planetas', planeta.toMap());
  }

  Future<List<Planeta>> getPlanetas() async {
    final List<Map<String, dynamic>> maps = await _db.query('planetas');
    return List.generate(maps.length, (i) {
      return Planeta.fromMap(maps[i]);
    });
  }

  Future<int> updatePlaneta(Planeta planeta) async {
    return await _db.update(
      'planetas',
      planeta.toMap(),
      where: 'id = ?',
      whereArgs: [planeta.id],
    );
  }

  Future<int> deletePlaneta(int id) async {
    return await _db.delete(
      'planetas',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class PlanetaListPage extends StatefulWidget {
  @override
  _PlanetaListPageState createState() => _PlanetaListPageState();
}

class _PlanetaListPageState extends State<PlanetaListPage> {
  List<Planeta> planetas = [];

  @override
  void initState() {
    super.initState();
    _loadPlanetas();
  }

  _loadPlanetas() async {
    final db = DBHelper();
    await db.initDB();
    List<Planeta> loadedPlanetas = await db.getPlanetas();
    setState(() {
      planetas = loadedPlanetas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Planetas")),
      body: ListView.builder(
        itemCount: planetas.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(planetas[index].nome),
            subtitle: Text(planetas[index].apelido ?? "Sem apelido"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanetaDetailPage(planeta: planetas[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlanetaPage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddPlanetaPage extends StatefulWidget {
  @override
  _AddPlanetaPageState createState() => _AddPlanetaPageState();
}

class _AddPlanetaPageState extends State<AddPlanetaPage> {
  final _nomeController = TextEditingController();
  final _distanciaController = TextEditingController();
  final _tamanhoController = TextEditingController();
  final _apelidoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Adicionar Planeta")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: "Nome"),
            ),
            TextField(
              controller: _distanciaController,
              decoration: InputDecoration(labelText: "Distância do Sol (UA)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _tamanhoController,
              decoration: InputDecoration(labelText: "Tamanho (km)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _apelidoController,
              decoration: InputDecoration(labelText: "Apelido (Opcional)"),
            ),
            ElevatedButton(
              onPressed: () async {
                final planeta = Planeta(
                  nome: _nomeController.text,
                  distanciaSol: double.parse(_distanciaController.text),
                  tamanho: double.parse(_tamanhoController.text),
                  apelido: _apelidoController.text.isEmpty ? null : _apelidoController.text,
                );
                final db = DBHelper();
                await db.initDB();
                await db.addPlaneta(planeta);
                Navigator.pop(context);
              },
              child: Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanetaDetailPage extends StatelessWidget {
  final Planeta planeta;

  PlanetaDetailPage({required this.planeta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(planeta.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Nome: ${planeta.nome}"),
            Text("Distância do Sol: ${planeta.distanciaSol} UA"),
            Text("Tamanho: ${planeta.tamanho} km"),
            Text("Apelido: ${planeta.apelido ?? 'Não possui'}"),
            ElevatedButton(
              onPressed: () async {
                final db = DBHelper();
                await db.initDB();
                await db.deletePlaneta(planeta.id!);
                Navigator.pop(context);
              },
              child: Text("Excluir"),
            ),
          ],
        ),
      ),
    );
  }
}
