# SuperVisorMobile — Brief : module "Projets & Tâches"

Document destiné à être fourni à un LLM comme contexte pour travailler sur ce module (implémentation, design d'API, revue). Il décrit (1) le périmètre existant tel qu'il est dans le code aujourd'hui, et (2) l'idée retenue pour le nouveau module. Rien de ce qui est décrit en section 2 n'est encore implémenté.

## 1. Contexte

SuperVisorMobile est une app Flutter de supervision retail (visites de magasins/points de vente). Stack : Flutter/Dart, modèles JSON manuels (`fromJson`/`toJson`, pas de codegen), services HTTP via `DioService` (`lib/services/DioService.dart`).

Un client (secteur retail — ouverture de magasins, ouverture de coffee shops, pas de contexte IT/dev) a demandé de fusionner deux notions dans l'app : la "checklist" (audit de conformité) et une notion de "mission/projet" avec tâches, responsables, deadlines, planning. Ce document sert de base pour concevoir cette fusion.

## 2. Périmètre existant (ce qui existe déjà dans le code, à ne pas casser)

Tout vit sous `lib/features/calendar/`. C'est un système d'**audit ponctuel de conformité**, pas un système de gestion de projet.

### 2.1 Entités existantes

**`Mission`** — `lib/features/calendar/models/missionModel.dart`
Une visite de contrôle sur un magasin donné, à une date planifiée.
Champs clés : `id`, `libelle`, `status` (int), `missionCode`, `description`, `createdAt`, `startedAT`, `planifiedAt`, `endedAt`, `startTime`, `endTime`, `boutiqueId` + `boutique` (→ `BoutiqueModel`), `userId`, `activated` (bool), `sousMissions` (`List<SousMission>?`), `modelReponseQuestionId`, `conformite_ID`, `scoreMax` (double), `totalQuestion` (int), `tauxConformite` (double), `progression` (double), `isMissed` (bool), `lateStart` (bool).

Notes : `modelReponseQuestionId` suggère qu'un mécanisme de "modèle réutilisable" existe peut-être déjà côté API pour Mission — à vérifier côté backend avant de concevoir un système de templates pour le nouveau module, pour ne pas dupliquer ce mécanisme.

**`SousMission`** — `lib/features/calendar/models/sousMissionModel.dart`
Une catégorie/section à l'intérieur d'une Mission.
Champs clés : `id`, `libelle`, `code`, `description`, `dateCreation`, `missionId`, `missionQuestions` (`List<QuestionMission>?`), `sommeValeurPositive` (int), `sommeCalculPoint` (double), `scoreMax` (double), `tauxConformiteCategorie` (double), `nombreQuestion` (int), `coefficient_ID` (int, pondération), `selectedCoefficient` (double), `typeIncident` (→ `IncidentCategory` enum-like), `incidentTypeId`.

**`QuestionMission`** — `lib/features/calendar/models/questionMissionModel.dart`
Une question individuelle à l'intérieur d'une SousMission, répondue en une fois lors de la visite.
Champs clés : `id`, `description`, `sousMissionId`, `reponse` (String, texte libre), `clouture` (DateTime, date de clôture de la question), `actionId` + `actions` (→ `ActionM`, action corrective liée), `commentaire`, `fileName` (pièce jointe), `choixReponseQuestion` (→ `ChoixReponseQuestion`, la réponse à choix fermé sélectionnée), `reponseID`, `selectedResponseValue` (int), `questionCoefficient` (double, pondération de la question), `incident` (bool), `jointureFichier`, `coef_ID`, `problemId`, `incidentTypeId` + `incidentType` (→ `IncidentType`), `departement_id`.

**`ChoixReponseQuestion`** — `lib/features/calendar/models/choixReponseQuestion.dart`
Un choix de réponse possible pour une question fermée (ex. Conforme / Non conforme / N.A.), rattaché à un `ModeleReponseQuestion` (`idModele`).
Champs clés : `id`, `valeur` (int, score associé au choix), `libelle`, `description`, `color` (pour l'affichage UI), `idModele`, `incident` (bool — ce choix déclenche-t-il un incident), `modeleReponseQuestion`.

**`BoutiqueModel`** — `lib/features/calendar/models/boutiqueModel.dart`
Le point de vente. Champs clés : `id`, `code`, `libelle`, `city`, `region`, `country`, `adress`, `datecreation`, plus des champs d'intégration ERP (`storeId`, `warehouseId`, `dbId`, `env`, `usernameCegid`, `passwordCegid`, `cluster`), `groupId` + `group` (→ `Group`).

**Autres modèles connexes** (mêmes dossier) : `ActionM` (`actionsModel.dart`, action corrective), `IncidentType` / `IncidentCategory` (`incidentTypeModel.dart`, `IncidentCategory.dart` dans `incidents/models/`), `Problem` (`Problem.dart`), `Group` (`groupModel.dart`), `Department` (`departement.dart`), `ModeleReponseQuestion` (`modelReponseQuestion.dart`), `PaginationModel` (`paginationModel.dart`), `MissionResponseModel` (`missionResponseModel.dart`, wrapper paginé `{ data: List<Mission>, pagination }`).

Service : `lib/features/calendar/services/missionService.dart`.
Écrans : `lib/features/calendar/screens/calendar.dart`, et widgets sous `lib/features/calendar/screens/widgets/` — `addMissionForm.dart`, `missionDetails.dart`, `mission_question.dart`, `questionResponse.dart`, `edit_question_response.dart`, `RapporterMissionWidget.dart`.

Module voisin qui suit une logique similaire (soumission + commentaires) : `lib/features/VisualMerchandising/` — `dtos/vm_submission_comments_page_dto.dart`, `dtos/vm_submission_comment_dto.dart`, `widgets/submission_comments_sheet.dart`. Potentiellement réutilisable pour un futur fil de commentaires sur une tâche.

### 2.2 Sémantique du modèle existant, à retenir

- Une Mission = **une visite, à une date, avec un score et un taux de conformité final**. Elle ne modélise pas une durée qui s'étend sur des semaines avec plusieurs personnes différentes impliquées à des moments différents.
- Hiérarchie fixe à 3 niveaux : Mission → SousMission → QuestionMission. Pas de notion de responsable par sous-élément, pas de deadline par question — la deadline/date est au niveau Mission entière.
- Notion de pondération déjà présente (`coefficient_ID`, `questionCoefficient`, `selectedCoefficient`) pour calculer un score global — utile si le futur module a besoin de pondérer des tâches.
- Notion d'incident déjà intégrée à la réponse d'une question (`ChoixReponseQuestion.incident`, `QuestionMission.incident` + `incidentTypeId`).

## 3. Besoin client (verbatim reformulé)

Le client fait de la gestion de projets retail non-IT (ouverture de magasin, ouverture de coffee shop, etc.). Chaque projet a plusieurs tâches à faire, chacune avec un responsable, une deadline, une place dans un planning. Le client veut que cette logique de "projet à tâches" et la logique "checklist" existante (Mission) soient réunies dans l'app, pas juste ajoutées côte à côte sans lien.

## 4. Idée retenue pour le nouveau module

### 4.1 Principe d'architecture

Ne pas étendre `Mission` pour lui faire porter la notion de tâche/projet — sa sémantique (audit ponctuel, score, taux de conformité) est étrangère à un projet qui dure plusieurs semaines et n'a pas de "score". À la place : ajouter un niveau au-dessus, sous forme de deux entités nouvelles, sans toucher à `Mission`/`SousMission`/`QuestionMission`.

```
Projet (nouveau)
 └─ Tache[] (nouveau)
      ├─ Tâche simple : statut + responsable + deadline + commentaire/pièce jointe
      └─ Tâche "checklist" : idem + missionId (optionnel) → pointe vers une Mission existante
```

Une Tâche référence une Mission via un champ `missionId` nullable — elle ne la remplace pas. Ouvrir une tâche qui a un `missionId` renseigné ouvre l'écran Mission déjà existant ; une tâche sans `missionId` est un simple item de statut.

### 4.2 Modèle de données proposé

**`Projet`** (nouveau)
- `id`: int
- `nom`: string — ex. "Ouverture Coffee Shop Marrakech"
- `type`: string — ex. "ouverture_magasin", "ouverture_coffee_shop" ; catégorie libre, extensible
- `boutiqueId`: int → `BoutiqueModel` (le point de vente concerné)
- `responsableGlobalId`: int? → User (chef de projet)
- `dateDebut`: datetime
- `dateFinPrevue`: datetime?
- `dateFinReelle`: datetime? (renseignée à la clôture)
- `statut`: enum — `planifie` | `en_cours` | `en_retard` | `termine`
- `progression`: double — calculée, voir 4.3

**`Tache`** (nouveau)
- `id`: int
- `projetId`: int → `Projet`
- `libelle`: string — ex. "Installer les rayonnages"
- `description`: string?
- `responsableId`: int → User (exécutant assigné)
- `deadline`: datetime
- `statut`: enum — `a_faire` | `en_cours` | `fait` | `en_retard` | `bloque`
- `ordre`: int? (position d'affichage dans le planning du projet)
- `commentaire`: string?
- `pieceJointe`: string? (fichier/photo justificatif)
- `missionId`: int? → `Mission` (si renseigné : tâche de type "checklist", ouvre l'écran Mission existant)

Aucun champ ajouté à `Mission`, `SousMission`, `QuestionMission`. Le lien est unidirectionnel (`Tache.missionId`), pas l'inverse.

### 4.3 Règles métier retenues

- **Progression du projet** = `(nombre de tâches statut=fait) / (nombre total de tâches)`. Poids égal par tâche en v1 (pas de pondération, contrairement à ce qui existe déjà sur QuestionMission).
- **Statut "en_retard" automatique** : une tâche passe en `en_retard` quand `deadline` est dépassée et que son statut n'est ni `fait` ni `bloque` (un blocage explicite prime sur le retard automatique). Le projet passe en `en_retard` dès qu'au moins une de ses tâches l'est.
- **Synchronisation Tâche ↔ Mission liée** : si `Tache.missionId` est renseigné, le statut de la tâche suit celui de la Mission plutôt que d'être modifiable manuellement — Mission non commencée → `a_faire` ; Mission en cours → `en_cours` ; Mission clôturée → `fait`. Une tâche liée ne peut pas être marquée `fait` manuellement si la Mission n'est pas clôturée.
- **Unicité du lien** : une même Mission ne doit être liée qu'à une seule Tâche à la fois (éviter qu'un audit serve à clôturer deux tâches de deux projets différents).
- **Permissions (hypothèse, à confirmer avec le client, alignée sur les rôles superviseur/exécutant déjà présents dans l'app)** : créer/éditer/clôturer un Projet → rôle superviseur uniquement. Changer le statut d'une tâche qui lui est assignée → l'exécutant assigné ou tout superviseur. Réassigner une tâche à quelqu'un d'autre → rôle superviseur uniquement.

### 4.4 Fonctionnalités envisagées

Pilotage (chef de projet) : liste des projets (filtrable par magasin/statut/type/période), création manuelle d'un projet avec ajout de tâches une à une, détail projet (progression + liste des tâches avec responsable/deadline/statut), alertes visuelles sur tâches en retard ou proches de l'échéance sans avoir commencé, réassignation de responsable / décalage de deadline, clôture de projet.

Exécution (responsable de tâche) : vue "Mes tâches" transverse tous projets confondus triée par deadline, changement de statut + commentaire/pièce jointe pour une tâche simple, ouverture directe de l'écran Mission pour une tâche checklist, historique de changement de statut (qui/quand).

Notifications : étendre le système de notifications déjà en place (ajouté récemment dans l'app, cf. commit "made corrections and added notifications") plutôt qu'en créer un second — notification à l'assignation d'une tâche, à J-1 de la deadline, à la tâche en retard (au responsable ET au chef de projet).

### 4.5 Périmètre MVP retenu

**Inclus en v1** : CRUD Projet et Tâche, lien optionnel Tâche↔Mission, détail projet avec progression calculée, vue "Mes tâches", historique de statut, notifications assignation + deadline.

**Explicitement reporté en v2** : templates de projet/tâche réutilisables (ex. modèle "Ouverture magasin" cloné à chaque nouvelle ouverture, avec délais relatifs J+X et rôles au lieu de personnes fixes — décision prise de les prévoir dans le modèle de données mais pas de les construire en v1), dashboard/reporting avancé et export PDF/Excel, dépendances entre tâches façon Gantt (écarté explicitement pour l'instant — deadlines indépendantes suffisent), fil de commentaires enrichi avec mentions (candidat naturel : réutiliser le pattern de `VisualMerchandising/widgets/submission_comments_sheet.dart`).

### 4.6 Questions ouvertes (non tranchées)

1. Le backend a-t-il déjà une notion de tâche/planning ailleurs dans le système, ou faut-il la créer entièrement côté API ? (Ce repo ne contient que le client Flutter — le backend n'a pas été inspecté.)
2. Les futurs templates de projet (v2) seront-ils globaux à l'enseigne, ou déclinés par région/type de point de vente ?
3. Une tâche peut-elle être déléguée par son responsable à quelqu'un d'autre, ou seul un superviseur réassigne ?
4. Faut-il pondérer certaines tâches plus que d'autres dans le calcul de progression (ex. "obtenir les autorisations" plus critique que "commander les fournitures"), ou l'égalité de poids suffit en v1 ?

## 5. Ce qui a été explicitement écarté ou reporté

- Étendre `Mission`/`SousMission`/`QuestionMission` pour leur faire porter directement responsable/deadline (rejeté — mélangerait deux sémantiques différentes).
- Dépendances entre tâches type Gantt en v1 (reporté).
- Templates de projet en v1, bien que prévus dans la conception du modèle pour ne pas devoir le retoucher plus tard (reporté à v2).
