class Livre {
  int? id;
  String? libelle;
  String? description;
  int? categorieId;
  int? auteurId;
  String? createdAt;

  Livre({
    this.id,
    this.libelle,
    this.description,
    this.auteurId,
    this.categorieId,
    this.createdAt,
  });

  Livre.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    libelle = json["libelle"];
    description = json["description"];
    auteurId = json["auteur_id"];
    categorieId = json["categorie_id"];
    createdAt = json["created_at"] ?? DateTime.now().toIso8601String();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["libelle"] = libelle;
    map["description"] = description;
    map["auteur_id"] = auteurId;
    map["categorie_id"] = categorieId;
    map["created_at"] = createdAt ?? DateTime.now().toIso8601String();
    return map;
  }
}
