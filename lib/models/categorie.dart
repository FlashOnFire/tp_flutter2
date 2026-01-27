class Categorie {
  int? id;
  String? libelle;
  String? updatedAt;

  Categorie({this.id, this.libelle, this.updatedAt});

  Categorie.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    libelle = json["libelle"];
    updatedAt = json["updated_at"] ?? DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["libelle"] = libelle;
    map["updated_at"] = updatedAt ?? DateTime.now().toIso8601String();
    return map;
  }
}
