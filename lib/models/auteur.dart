class Auteur {
  int? id;
  String? nom;
  String? prenoms;
  String? email;

  Auteur({this.id, this.nom, this.prenoms, this.email});

  Auteur.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    nom = json["nom"];
    prenoms = json["prenoms"];
    email = json["email"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["nom"] = nom;
    map["prenoms"] = prenoms;
    map["email"] = email;
    return map;
  }
}
