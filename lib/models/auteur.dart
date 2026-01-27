class Auteur {
  int? id;
  String? nom;
  String? prenoms;
  String? email;
  String? createdAt;

  Auteur({this.id, this.nom, this.prenoms, this.email, this.createdAt});

  Auteur.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    nom = json["nom"];
    prenoms = json["prenoms"];
    email = json["email"];
    createdAt = json["created_at"] ?? DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["nom"] = nom;
    map["prenoms"] = prenoms;
    map["email"] = email;
    map["created_at"] = createdAt ?? DateTime.now().toIso8601String();
    return map;
  }
}
