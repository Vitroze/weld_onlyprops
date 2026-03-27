# Weld Only Props

Permet de souder uniquement des `prop_physics` appartenant au joueur, avec plusieurs restrictions pour eviter les abus.

## Fonctionnalites

- Soude uniquement des entites de type `prop_physics`.
- Verifie que le joueur est proprietaire des props avant de permettre la soudure.
- Empeche les soudures abusives:
  - cooldown entre actions,
  - limite globale de soudures par joueur,
  - limite de soudures sur un meme prop,
  - blocage si les props sont trop eloignes,
  - blocage de la double soudure entre les memes deux props,
  - blocage de la soudure d'un prop sur lui-meme.
- Possibilite de desouder via la touche de rechargement (`R`).
- Les collisions des props enfants sont désactivées pour éviter les problèmes de physique

## Installation

Placez le dossier de l'addon dans:

`garrysmod/addons/weld_onlyprops`

Le Tool est charge depuis:

`lua/weapons/gmod_tool/stools/vitroze_weld_onlyprop.lua`

## Utilisation en jeu

- Outil: `Souder (Seul les props)`
- Categorie: `Constraints`

Controles:

- `Clic gauche`: selection du premier prop puis du second prop pour souder.
- `R`: retire les contraintes Weld du prop vise.

## ConVars

- `sbox_maxvitroze_weld_onlyprops` (defaut: `10`)
  - Nombre maximum de soudures posees par joueur.
- `vitroze_weld_maxonlyprop` (defaut: `2`)
  - Nombre maximum de soudures autorisees sur un meme prop.

## Regles appliquees par le Tool

- Le joueur doit viser un `prop_physics`.
- Le joueur doit etre proprietaire du prop.
- Le prop cible doit etre a proximite du joueur.
- Les deux props doivent etre assez proches l'un de l'autre pour etre soudes.
- Une seule liaison logique est maintenue entre les deux props (pas de doublon entre la meme paire).

## Notes

- Les valeurs de distance sont codees en distance au carre (`DistToSqr`) dans le script.
- Le comportement de collision de l'entite enfant est ajuste pendant certaines interactions Physgun.
