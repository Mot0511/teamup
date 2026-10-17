class Game {
  final int id;
  final String name;

  Game({required this.id, required this.name});

  static final Map<int, String> _names = {};

  static void registerName(int id, String name) {
    if (id != 0 && name.isNotEmpty) _names[id] = name;
  }

  static String nameFor(int id) => _names[id] ?? '';

  factory Game.fromJSON(Map data) {
    final int id = (data['id'] as num).toInt();
    final String name = '${data['title'] ?? data['name'] ?? ''}';
    registerName(id, name);
    return Game(id: id, name: name);
  }

  factory Game.fromId(int id) => Game(id: id, name: nameFor(id));
}