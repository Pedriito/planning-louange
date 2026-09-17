# Planning Louange — saison 2026-2027

Planning annuel de la section Louange de l'Église la Rencontre : la rentrée, la prière
toutes les deux semaines, un séminaire par trimestre, un jeûne et prière par mois, un
temps détente mensuel et une formation spirituelle ou technique tous les deux mois.

Tout tient dans un seul fichier HTML, sans build ni dépendance. Ouvrir `index.html`
dans un navigateur suffit.

## Ce qu'il y a dedans

- Un aperçu des douze mois de la saison, avec un repère coloré par temps prévu.
- Des filtres par type pour n'afficher qu'une catégorie.
- Chaque temps est modifiable directement : date, titre, type, horaire, lieu, qui pilote,
  statut (à caler / confirmé) et une zone de notes.
- Ajout, duplication et suppression par mois.
- Export `.ics` pour envoyer toute la saison dans un agenda.
- Une feuille d'impression propre, pour distribuer le planning à l'équipe.

## Comment c'est fait

Un seul fichier, `index.html`, avec trois blocs :

- le CSS en haut, avec les couleurs en variables (`--priere`, `--jeune`, `--seminaire`…)
  et un thème sombre basé sur `prefers-color-scheme` ;
- le HTML, très court : un bandeau, une barre d'outils, l'aperçu, le conteneur des mois ;
- le JavaScript, sans framework. La fonction `proposition()` contient la cinquantaine
  de dates proposées ; `rendu()` reconstruit la page à partir de l'état ; les
  modifications passent par délégation d'évènements sur le conteneur `#annee`.

Un évènement ressemble à ça :

```js
{ id, date: "2026-11-14", titre, type, heure, lieu, qui, notes, statut }
```

Les types possibles sont `rentree`, `priere`, `jeune`, `seminaire`, `detente`,
`formation` et `autre`. Pour en ajouter un, il faut une entrée dans l'objet `TYPES`,
son nom dans `ORDRE_TYPES` et une variable de couleur dans le CSS (mode clair et
mode sombre).

## Sauvegarde

Deux chemins, dans cet ordre :

1. Publié comme artefact Claude, le planning utilise la base partagée de l'artefact
   (`claude.use("db")`, document `planning/saison-2026-2027`). Toutes les personnes qui
   ont l'accès en édition travaillent sur les mêmes données.
2. Partout ailleurs — fichier local, GitHub Pages, Vercel — il n'y a pas de base
   partagée : `window.claude` n'existe pas et le code retombe sur `localStorage`.
   Chacun garde alors ses modifications dans son propre navigateur.

C'est le point à garder en tête avant de déployer : héberger le fichier donne une URL
publique, pas de l'édition à plusieurs. Pour du vrai travail collaboratif il faut soit
partager l'artefact, soit brancher un backend (Supabase ferait l'affaire, la logique de
chargement et d'enregistrement est déjà isolée dans `charge()` et `enregistre()`).

## Déployer

GitHub Pages : pousser le dépôt, puis Settings → Pages → branche `main`, dossier racine.

Vercel : importer le dépôt, aucun réglage de build, le fichier est servi tel quel.

## Pistes

- Suivi des présences ou des rotations par temps.
- Un second onglet pour le planning des cultes, à côté du planning interne.
- Import depuis Planning Center plutôt que saisie manuelle.
- Backend partagé (voir plus haut) si l'équipe veut éditer à plusieurs hors de Claude.
