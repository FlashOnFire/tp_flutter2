class Livre {
  int? id;
  String? libelle;
  String? description;
  int? nbPage;
  String? image;
  int? categorieId;
  int? auteurId;

  Livre({
    this.id,
    this.libelle,
    this.description,
    this.nbPage,
    this.image,
    this.auteurId,
    this.categorieId,
  });
}
