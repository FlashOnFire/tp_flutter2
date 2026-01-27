class Categorie {
  int? id;
  String? libelle;
  String? createdAt;

  Categorie({this.id, this.libelle, this.createdAt});

  Categorie.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    libelle = json["libelle"];
    createdAt = json["created_at"] ?? DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["libelle"] = libelle;
    map["created_at"] = createdAt ?? DateTime.now().toIso8601String();
    return map;
  }
}
