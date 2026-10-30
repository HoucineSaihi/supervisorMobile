# Changelog — Mobile (Flutter)

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Versionnement [SemVer](https://semver.org/lang/fr/). La procédure de release est décrite dans `RELEASING.md`.

## [Non publié]

## [3.5.0] - 2026-10-30

### Ajouté
- Écran « À propos » (Profil) affichant le nom de l'application, la version et le numéro de build installés, avec copie de `version+build`.

### Notes
- Version alignée avec le web et le backend (module Store Performance, front-end uniquement). Aucun changement fonctionnel côté mobile pour ce module.
- Numéro de build inchangé (`+2`) : aucun binaire n'a quitté la machine depuis la dernière livraison.

## [3.3.0] - 2026-10-08

Version de référence. Première version taguée: elle réunit la ligne Visual Merchandising (VM) et Smart Messenger sur le tronc `smart-messenger-phase1`.

### Inclus
- Module Smart Messenger (messagerie, cache média, instantanés hors ligne, incidents).
- Module Visual Merchandising (campagnes, exécution, correction du mappage des statuts de zone).
- Rapport d'évaluation VM (écran, sélection de boutiques et de modèles de grille, traductions FR/EN).
- Notifications.

### Notes
- Numéro de build: `3.3.0+1`.
