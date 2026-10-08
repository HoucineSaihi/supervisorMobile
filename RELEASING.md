# Procédure de release

Cette procédure s'applique aux **trois projets**, qui partagent un **seul numéro de version produit** (SemVer `MAJOR.MINOR.PATCH`):

| Projet | Dépôt local | Fichier de version |
|---|---|---|
| Mobile (Flutter) | `SuperVisorMobile` | `pubspec.yaml` → `version: X.Y.Z+N` |
| Web (Angular) | `supervisorFrontEndAzure/Super-Visor` | `package.json` + `package-lock.json` (2 lignes) |
| Backend (.NET) | `supervisorBackendAzure` | `DIGICARDBACK.csproj` → `<Version>X.Y.Z</Version>` |

**Tronc:** `smart-messenger-phase1`. Les releases sont toujours taguées depuis le tronc.
**Tag:** `vX.Y.Z`, annoté, identique dans les trois dépôts. Version de référence actuelle: `v3.3.0`.

## Choisir le numéro

| Changement | On incrémente | Exemple |
|---|---|---|
| Correction de bug, sans nouveauté | PATCH | 3.3.0 → 3.3.1 |
| Nouvelle fonctionnalité compatible | MINOR | 3.3.1 → 3.4.0 |
| Rupture (schéma, contrat, migration lourde) | MAJOR | 3.4.0 → 4.0.0 |

## A. À chaque release (nouveau numéro)

Dans **chacun des trois dépôts**:

1. `git switch smart-messenger-phase1` puis `git pull`. `git status` doit être propre.
2. Écrire le nouveau numéro dans le fichier de version (tableau ci-dessus). Même numéro partout.
3. Compléter `CHANGELOG.md` (une entrée pour la version, par dépôt).
4. Commit: `chore: release X.Y.Z`.
5. Tag annoté: `git tag -a vX.Y.Z -m "<message>"`.
6. Pousser la branche **puis** le tag: `git push origin smart-messenger-phase1` et `git push origin vX.Y.Z`.
7. Vérifier: `git ls-remote --tags origin "vX.Y.Z*"`.

Règle: un tag poussé ne se déplace jamais. En cas d'erreur, on publie une version corrective (`X.Y.Z+1` en PATCH).

## B. À chaque build livré

1. `git checkout vX.Y.Z` (construire **depuis le tag**, jamais depuis un dossier de travail en cours). `git status` propre.
2. Construire (commandes ci-dessous).
3. Test rapide: la version affichée dans l'app doit être la bonne.
4. Nommer l'artefact avec la version et le profil, et le ranger (GitHub Releases ou dossier partagé):
   `supervisor-<profil>-<version>-<plateforme>.<ext>`
5. Ajouter une ligne au **tableau de déploiement** (section D).
6. Revenir sur le tronc: `git switch smart-messenger-phase1`.

### Commandes de build

```
# Flutter (Android)
flutter build apk --release --build-name=X.Y.Z --build-number=N
flutter build appbundle --release --build-name=X.Y.Z --build-number=N

# Angular
ng build --configuration production        # sortie: dist/digi-card-new-front

# Backend (.NET)
dotnet publish -c Release -p:Version=X.Y.Z
```

## C. Le numéro de build mobile (`+N`)

- Il augmente à chaque binaire qui **quitte ta machine** (store, TestFlight, APK livré). Pas pour un simple `flutter run`.
- Il **ne redescend jamais**, même quand la version change: `3.3.0+1` → `3.3.0+2` → `3.3.1+3` → `3.4.0+4`. Sur Android, un `versionCode` plus petit refuse la mise à jour.
- Recompiler le même code (rejet du store, autre profil client)? Garde le même tag et passe un nouveau numéro avec `--build-number=N`, sans modifier `pubspec.yaml`.
- Dernier numéro de build utilisé: **1** (à mettre à jour ici après chaque livraison).

## D. Tableau de déploiement

Une ligne par livraison, pour savoir qui a quoi.

| Date | Client | Composant | Version | Build | Profil / modules | Fait par | Remarque |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## E. Repères historiques (avant la version 3.3.0)

Pour retrouver ce que tournait un client avant la migration, utiliser les tags `legacy/...` (voir CHANGELOG).
