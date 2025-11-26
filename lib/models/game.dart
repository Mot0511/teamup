class Game {
  final int id;
  final String name;

  Game({required this.id, required this.name});

  factory Game.fromJSON(Map data) {
    return Game(
      id: data['id'],
      name: data['name']
    );
  }
}