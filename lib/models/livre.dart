class Livre {
  int? id;
  String? libelle;
  String? description;
  int? categorieId;
  int? auteurId;

  Livre({
    this.id,
    this.libelle,
    this.description,
    this.auteurId,
    this.categorieId,
  });

  Livre.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    libelle = json["libelle"];
    description = json["description"];
    auteurId = json["auteur_id"];
    categorieId = json["categorie_id"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {};
    map["id"] = id;
    map["libelle"] = libelle;
    map["description"] = description;
    map["auteur_id"] = auteurId;
    map["categorie_id"] = categorieId;
    return map;
  }
}
