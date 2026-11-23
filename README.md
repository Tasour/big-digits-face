# Big Digits — Forerunner 955 Solar

Cadran Connect IQ pour **Garmin Forerunner 955 / 955 Solar**, inspiré d'un
affichage numérique à gros chiffres 7 segments.

![Aperçu du cadran Big Digits](result-watch.png)

*Aperçu : VEN 13 NOV, 01:25, 1 000 kcal, 20 000 pas, 12H.*

## Fonctionnalités

- Quatre chiffres 7 segments de **90 × 90 px**, trait de 18 px, dessinés
  directement en Monkey C (aucune police externe).
- `1` custom centré, en barre verticale, comme celui des secondes.
- Secondes horizontales en bas au centre : deux chiffres **10 × 14**, trait 2 px.
- Date : jour en **7 segments 12 × 18**, jour de la semaine et mois en police
  trait **10 × 12** (1 px), en blanc.
- Calories actives à gauche et pas à droite, en colonnes verticales de chiffres
  **7 segments 10 × 14**, en blanc, avec petits repères `C` et `P` en gris.
  Les calories actives sont estimées : Connect IQ ne fournit que le total
  journalier, le cadran soustrait les calories de repos calculées depuis le
  profil utilisateur.
- Autonomie restante à droite des secondes : nombre **7 × 11**, trait 1 px, gris,
  unité `J`/`H` en petit, en haut à droite.
- Point de connexion téléphone à gauche des secondes (visible uniquement si la
  montre est connectée).
- Quatre arcs segmentés à `r=126`.
- Mise à jour chaque minute + `onPartialUpdate` pour les secondes.

## Big Digits Chrono

Application chronomètre assortie au cadran, dans le même langage 7 segments.
Elle s'installe à côté du cadran et se lance depuis la liste des applications.

![Chrono — aperçu des états](chrono-preview.png)

| READY | En course | Après 1 h |
| --- | --- | --- |
| ![READY](chrono-ready.png) | ![Course](chrono-running.png) | ![Heures](chrono-hours.png) |

### Principe

- **H M S** sur une ligne, **centièmes** au centre en bas.
- Avant 1 h : `M S CM` sur la ligne, `CM` prend la place libre à droite.
- Après 1 h : `H M S` sur la ligne, `CM` en bas.
- Le groupe du milieu reste **centré** et **1,6× plus grand** que les côtés
  (proportions du nombre d'or).
- Zéros de tête masqués ; centièmes toujours sur 2 chiffres.
- `Are you READY ?` avant le départ (seul `READY` est gras), `GO!` pendant 3 s,
  puis plus aucun texte.
- Aucune fioriture : pas d'arc, pas de flèche, pas de statut.

### Commandes

| Bouton | Action |
| --- | --- |
| Haut droite — START/STOP | Lancer / pause |
| Bas droite — BACK | Remise à zéro |
| Haut gauche — LIGHT | Lap (affiche le tour 2 s) |
| Bas gauche — DOWN | Retour au cadran |
| Milieu gauche — UP | Inutilisé |

### Compilation et installation

```bash
cd chrono
./build.sh
# -> chrono/bin/bigdigits-chrono-fr955.prg
```

Copier `chrono/bin/bigdigits-chrono-fr955.prg` dans `GARMIN/Apps/`, puis
débrancher/rebrancher la montre. L'application apparaît sous **Big Digits
Chrono**.

### Technique

- Temps calculé depuis `System.getTimer()` (pas d'accumulation d'erreurs).
- Timer de 20 ms pour les centièmes, arrêté en pause pour préserver la batterie.
- Lap : flash du temps du tour pendant 2 s.
- Même moteur 7 segments que le cadran (primitives graphiques, aucune police).

## Rappels Protocoles (branche `protocol-popups`)

Onze rappels sont dessinés **directement dans le cadran** sous forme d'un
rectangle blanc avec titre, message et un buzz unique. Le contenu est généré
depuis la base de connaissances RAG (EPUB *Protocols* de Huberman) et intégré
aux ressources `resources/strings/strings.xml` : les watch faces ne peuvent pas
recevoir de texte par `Communications`, et `WatchUi.pushView` est interdit
(`OperationNotAllowedException`). Les données Garmin ne servent que de
déclencheur (nombre de pas à 18 h 30).

| Heure | Rappel |
|---|---|
| 07:00 | 10-30 MIN DE LUMIERE AU REVEIL |
| 08:00 | Protocole du jour (cyclique lun→dim, 7 variantes) |
| 12:30 | MARCHE 5-10 MIN APRES LE REPAS |
| 15:00 | PLUS DE CAFEINE NI D ALCOOL CE SOIR |
| 17:30 | VA VOIR LE COUCHE DE SOLEIL / 10-15 MIN FACE A L OUEST |
| 18:30 | PAS ASSEZ DE PAS — MARCHE 5 MIN (si pas < 7 000), sinon OBJECTIF PAS ATTEINT |
| 20:30 | 4 MOUVEMENTS 2-4 FOIS PAR SEMAINE |
| 21:00 | NSDR 20 MIN SI SOMMEIL INSUFFISANT |
| 21:30 | 18-20 C — EXTREMITES CHAUDES |
| 22:00 | ECRANS OFF 1 H AVANT LE COUCHER |
| 22:30 | 1-3 SOUPIRS PHYSIOLOGIQUES |

Chaque message reste affiché deux minutes. La vibration est protégée par
`Attention has :vibrate` et respecte `DeviceSettings.vibrateOn` ; sur
Forerunner le motif de vibration n'est pas supporté : un seul buzz, cycle fixe.
Les passages sources sont archivés dans `docs/rag-messages.md`.

Limites : textes figés à la compilation (pas de mise à jour dynamique), pas de
`pushView` depuis une watch face, pas de personnalisation des heures sans
recompiler.

### Preuve visuelle (simulateur)

Captures relues sur le device `fr955` (cadran de test temporaire forçant le
créneau, car le champ « Time Simulation » n'entre pas 17:30 de façon fiable) :

| Fichier | Créneau | Contenu lisible |
|---|---|---|
| `docs/popup-0700-reveil.png` | 07:00 | REVEIL / 10-30 MIN DE LUMIE... |
| `docs/popup-1730-coucher.png` | 17:30 | SOLEIL / VA VOIR LE COUCH / FACE A L OUEST |
| `docs/popup-2230-calm.png` | 22:30 | CALME / 1-3 SOUPIRS |

Le binaire livré (`bin/bigdigits-fr955.prg`) est compilé depuis le code non
modifié : le test n'a servi qu'à visualiser le rendu du popup.

Deux défauts observés puis corrigés : le premier crop de preuve montrait le gizmo
Blender au lieu du cadran ; et le texte débordait du rectangle sur les messages
longs. `drawPopup` applique désormais un wrap à 16 caractères (`FONT_SMALL`) et
tronque le sous-titre à 14 (`FONT_TINY`). Les messages les plus longs ont été
raccourcis dans `strings.xml`.

Pour lancer le simulateur sur Arch : le binaire 9.3.0 demande les SONAME legacy
`libwebkit2gtk-4.0.so.37`, `libjavascriptcoregtk-4.0.so.18`, `libsoup-2.4.so.1`
(absents d'Arch qui fournit 4.1/3.0). Un répertoire de compatibilité avec des
symlinks isolés via `LD_LIBRARY_PATH` suffit. Charger l'app avec
`monkeydo <prg> fr955` (l'argument .prg de `simulator` seul ne la charge pas).

## Compilation

Prérequis :

- Connect IQ SDK **9.3.0** (ou compatible avec l'API 5.2) ;
- device `fr955` installé ;
- Java 21 ;
- clé de développeur **RSA 4096** au format DER.

`build.sh` lit le chemin du SDK dans `~/.Garmin/ConnectIQ/current-sdk.cfg` et
attend la clé `developer_key.der` à la racine du projet.

```bash
./build.sh
# -> bin/bigdigits-fr955.prg
```

Les clés de signature (`*.der`, `*.pem`), les sauvegardes et le dossier `bin/`
ne sont **pas versionnés** (voir `.gitignore`). Placez votre propre
`developer_key.der` à la racine avant de compiler.

## Installation

1. Brancher la montre en mode MTP.
2. Copier `bin/bigdigits-fr955.prg` dans `GARMIN/Apps/`.
3. Débrancher/rebrancher la montre pour déclencher le scan.
4. Sélectionner « Big Digits » comme cadran.

## Structure

```text
source/              Sources Monkey C du cadran
  BigDigitsApp.mc
  BigDigitsView.mc
resources/            Icône et chaînes
manifest.xml          Manifest Connect IQ du cadran
monkey.jungle         Configuration de build
build.sh              Script de compilation du cadran
result-watch.png      Aperçu du cadran
chrono/               Application chronomètre
  source/
    ChronoApp.mc
    ChronoDelegate.mc
    ChronoView.mc
  resources/          Icône et chaînes
  manifest.xml        Manifest Connect IQ du chrono
  monkey.jungle       Configuration de build
  build.sh            Script de compilation du chrono
chrono-preview.png    Aperçu des états du chrono
chrono-ready.png      Chrono — READY
chrono-running.png    Chrono — en course
chrono-hours.png      Chrono — après 1 h
```

## Compatibilité

- Forerunner 955 / 955 Solar
- Écran rond 260 × 260, MIP 64 couleurs
- `minSdkVersion` : 5.2.0
- Format 12 h / 24 h selon le réglage de la montre
- Libellés de date en français

## Remarques

- L'app ID Connect IQ et le nom de l'application sont définis dans
  `manifest.xml`.
- Le cadran ne dépend d'aucune ressource de police externe : les chiffres,
  les lettres de la date et les unités sont dessinés en primitives graphiques.
- `ActivityMonitor.Info.calories` donne les calories totales de la journée, pas
  les calories actives. Le cadran estime les calories de repos à partir de
  l'âge, la taille, le poids et le sexe du profil (`UserProfile`), puis les
  soustrait du total. Le résultat peut différer de quelques kcal de Garmin
  Connect.
- L'application déclare la permission `UserProfile` dans `manifest.xml`.
