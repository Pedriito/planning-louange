# Planning Louange — saison 2026-2027

Planning annuel de la section Louange de l'Église la Rencontre : la rentrée, la prière
toutes les deux semaines, un séminaire par trimestre, un jeûne et prière par mois, un
temps détente mensuel et une formation spirituelle ou technique tous les deux mois.

Une seule page HTML, sans build. L'équipe l'édite à plusieurs : la page est ouverte
en lecture à tous, et l'édition se déverrouille avec le code de la section.

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

## Édition à plusieurs

Le planning vit dans une base Supabase partagée. Concrètement :

- **Tout le monde lit.** Ouvrir l'URL suffit, sans compte ni code.
- **L'équipe écrit.** Le bouton « Déverrouiller l'édition » demande le code d'équipe.
  Sans lui, les champs sont en lecture seule et les boutons d'ajout disparaissent.
- **Chacun voit les autres en direct.** Une modification enregistrée arrive dans les
  autres navigateurs ouverts en une seconde ou deux, sans rechargement. La page attend
  que tu aies fini de taper avant d'appliquer un changement venu d'ailleurs.

Le code n'est pas dans ce dépôt — demande-le au responsable de la section. Il est gardé
haché en base (bcrypt) et vérifié côté serveur ; dix essais ratés par quart d'heure et
par adresse IP et la vérification se ferme. Une fois saisi, il reste dans le navigateur
pour ne pas avoir à le retaper.

La table `planning` est en lecture seule pour la clé publique : la seule écriture
possible passe par la fonction `enregistrer_planning`, qui exige le code. La clé
publique dans `index.html` n'ouvre donc rien à elle seule.

Pour changer le code : `select changer_code('<code actuel>', '<nouveau>');`

Si la base est injoignable, la page retombe sur `localStorage` et le dit dans la barre
d'état — les modifications restent alors dans le navigateur.

## Ce qu'il y a côté base

`supabase/schema.sql` contient tout : tables, RLS, fonctions. Rejouable sur un projet
neuf. Trois tables, une seule ligne de données utile :

- `planning` — le planning entier en `jsonb`, avec un compteur `version`.
- `planning_acces` — le code haché, illisible depuis l'extérieur.
- `planning_tentatives` — les essais ratés, pour le plafond par IP.

Le compteur `version` sert à ne pas écraser le travail d'un autre : si la version a
bougé pendant que tu éditais, l'enregistrement est refusé et la page recharge la version
du serveur. Rare, puisque tout le monde reçoit les changements en direct, mais dans ce
cas la modification en cours est perdue — c'est la limite connue du système.

## Déployer

GitHub Pages : Settings → Pages → branche `main`, dossier racine.

Vercel : importer le dépôt, aucun réglage de build, le fichier est servi tel quel.

Dans les deux cas rien à configurer : l'URL et la clé publique Supabase sont dans
`index.html`.

## Pistes

- Suivi des présences ou des rotations par temps.
- Un second onglet pour le planning des cultes, à côté du planning interne.
- Import depuis Planning Center plutôt que saisie manuelle.
- Un rôle « lecture seule » distinct du code d'édition, si la section grandit.
