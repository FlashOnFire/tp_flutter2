class Categorie {
  int? id;
  String? libelle;

  Categorie({this.id, this.libelle});

  Categorie.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    libelle = json["libelle"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["libelle"] = libelle;
    return map;
  }
}
