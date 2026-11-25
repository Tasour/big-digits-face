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

Huit rappels sont dessinés **directement dans le cadran** sous forme d'un
rectangle noir à bordure colorée, avec titre, message sur une ligne et barre
d'habitude de 7 carrés portant les lettres `LMMJVSD`. Le contenu vient de la
base RAG Synthetix (EPUB *Protocols* de Huberman) et est intégré aux chaînes
compilées : une watch face ne peut ni recevoir de texte par `Communications`,
ni appeler `WatchUi.pushView`. Les données Garmin servent de déclencheur.

| Heure | Rappel | Déclencheur |
|---|---|---|
| 07:00 | Réveil — Part regarder le lever de soleil | réveil configuré |
| 12:30 | Repas — Marche 5-10 min après le repas | créneau fixe |
| 15:00 | Stimulants — Plus de caféine ni d'alcool ce soir | coucher − 8 h |
| 17:30 | Soleil — Part regarder le coucher de soleil | position solaire NOAA |
| 18:30 | Pas — Marche 5 min, pas assez | pas < 85 % du stepGoal |
| 21:00 | NSDR — 30 / 20 / 10 / 10 min selon le moment | stress, sommeil, heure |
| 22:00 | Écrans — Écrans off 1 h avant le coucher | coucher − 1 h |
| 22:30 | Calme — 1-3 soupirs physiologiques | stress > 40 |

Chaque rappel dure 25 s. Le cadran ne peut pas vibrer (`Toybox.Attention` est
interdit dans une watch face) : le buzz est assuré par l'app compagnon
`companion/`, voir section dédiée plus bas. Les passages sources sont archivés
dans `docs/rag-messages.md`.

**Réglages sur la montre** : `UP/MENU` → *Cadran* → *Personnaliser* ouvre un
menu `Menu2` avec « Secondes » et « Rappels ». Les valeurs sont persistées dans
le stockage de la face (`face.showSeconds`, `face.showPopups`, défaut activé).

Limites : pas de `pushView` depuis une watch face, pas de personnalisation des
heures sans recompiler (prévu en P1 via `docs/architecture/ROADMAP.md`). Les
12 captures (8 messages + 4 variantes) sont indexées dans `docs/screens/README.md`.

Correctifs P0 livrés : l'historique d'habitude n'est plus effacé après un jour
manqué (`shiftHabitBits`), le planning background utilise un `Moment` avec un
minimum de 5 minutes, l'auto-test à 10 s a été retiré, et l'appui long suit
l'ordre accuser → complication → test.

Algorithmes affinés dans l'app : événements réels `onSleepTime`/`onWakeTime`,
moyenne circulaire du coucher et du lever sur 7 jours, durée de nuit déduite de
ces événements, Body Battery désormais testé par seuil (et non par simple
présence), objectif de pas pondéré par la fenêtre lever–dodo, NSDR dont la durée
affichée dépend de la nuit et du stress, tendance de stress sur 1 h pour Calme.
Le score de sommeil natif n'est pas exposé par le device `fr955`
(`docs/architecture/DATA-SOURCES.md`) : il reste `notMeasured`.

### Lien téléphone — deux boucles (ADR-0014)

La montre décide seule. Le téléphone ne fait que corriger, une fois par jour.

- **Montre → téléphone** : une trame binaire de **62 octets** à la première
  ouverture de l'application au premier plan (ou depuis le panneau de test), avec réveil,
  coucher visé, écrans off, caféine, moyennes, dette, écart-type du coucher,
  stress z × 100, Body Battery, pas, soleil, score NSDR, slot et raison.
- **Téléphone → montre** : **40 octets** de corrections (`needMin`, `debt7`,
  `bedSD`, `verdict`, `nsdrMin`, `exp`), validées par version, longueur, CRC-16,
  expiration et bornes. Une correction périmée est ignorée et le calcul local
  reprend, sans message.
- **Transport** : `Communications.transmit` / `registerForPhoneAppMessages`,
  BLE uniquement, zéro URL, zéro cloud. Une seule requête en vol ; en cas
  d'échec, nouvelle tentative à la prochaine ouverture, trois fois par jour.
- **Diagnostic** : deux lignes `BLE:` (envoi / ok / attente / abandon / rejeté)
  et `Src:` (`local` ou `connect`) sur l'écran de diagnostic.

Le contrat complet, offset par offset, est dans
`docs/architecture/PHONE-CONTRACT.md`. Vérification du format sans téléphone :

```bash
./scripts/run-watch-tests.sh      # 50 tests, dont 19 sur le contrat binaire
./scripts/check-timing-parity.sh  # parité face / compagnon
```

Le transport BLE réel reste **`notMeasured`** : il exige une application
téléphone qui parle le protocole Garmin. Rien n'est déclaré prouvé à sa place.

### Méthode de capture

Les captures sont prises sur le device `fr955` avec un cadran de test temporaire
forçant le créneau : le champ « Time Simulation » du simulateur n'entre pas
17:30 de façon fiable. Le cadran de test appelle `setPopup()` avec les vraies
chaînes compilées ; le binaire livré reste compilé depuis le code non modifié.

Trois défauts observés puis corrigés au fil des captures : un crop montrait le
gizmo Blender au lieu du cadran ; le texte débordait du rectangle sur les
messages longs ; enfin `wrapText()` démarrait avec une entrée vide, ce qui
masquait la première ligne et tronquait le message. Le wrap est à 18 caractères
et les messages sont dimensionnés pour deux lignes. Voir `docs/screens/`.

Pour lancer le simulateur sur Arch : le binaire 9.3.0 demande les SONAME legacy
`libwebkit2gtk-4.0.so.37`, `libjavascriptcoregtk-4.0.so.18`, `libsoup-2.4.so.1`
(absents d'Arch qui fournit 4.1/3.0). Un répertoire de compatibilité avec des
symlinks isolés via `LD_LIBRARY_PATH` suffit. Charger l'app avec
`monkeydo <prg> fr955` (l'argument .prg de `simulator` seul ne la charge pas).

## Design v2 (2026-11-24)

Règles appliquées : `~/.config/opencode/design/UNIVERSAL_DESIGN_RULES.md` v1.9.0.
Mesures et arbitrages : `docs/messages-v2.md`, `docs/rag-messages.md`,
`docs/design-measures.md` (hors dépôt, `~/.opencode-poc/`).

- **Casse** : titre en Title Case, message en phrase (U01/U18). Accents `é è °`
  confirmés sur `fr955` (`accent-test.png`).
- **Hiérarchie** (U03/U33) : titre `FONT_SMALL`, message `FONT_SYSTEM_XTINY`,
  contexte affiché seulement si le message tient sur une ligne. Échelle fermée.
- **Rectangle** (U79) : 220×138 centré à (20,61), **fond noir et texte blanc**.
  Ses quatre coins tombent sur le cercle d'affichage (rayon 130). Bordure
  pleine de 3 px colorée par catégorie (U19/U41) : orange = lumière,
  bleu = marche/pas, violet = stimulants/soleil/NSDR/écrans/calme.
- **Centrage** : titre, message et barre centrés horizontalement et
  verticalement (`TEXT_JUSTIFY_CENTER | TEXT_JUSTIFY_VCENTER`).
- **Habitude (forme)** : 7 carrés de 30 px, espacés de 2 px, avec au centre la
  lettre du jour concerné (`LMMJVSD`, bit 0 = aujourd'hui). Plein = couleur de
  bordure et lettre noire ; vide = contour blanc et lettre blanche.
  Exemple : `docs/screens/habit-partiel-popup.png`.
- **Durée** (U62) : 25 s, vérifiée dans `onPartialUpdate`.
- **Wrap** (U73) : `wrapText()` démarre avec un tableau vide. Une entrée `""`
  initiale masquait la première ligne et tronquait tous les messages ; la
  la découpe est à 30 caractères avec `FONT_SYSTEM_XTINY` dans 214 px utiles.
  Défauts corrigés après relecture des captures.
- **Habitude** : barre de 7 carrés, fenêtre glissante 7 jours, un seul appui par
  jour via `WatchFaceDelegate` (bouton haut droit). Score persisté dans
  `Application.Storage`. Un second appui est ignoré.
- **Checks réels** : pas < 85 % du `stepGoal`, stress > 50, position solaire NOAA
  en cache, réveil et coucher dérivés du profil, caféine/alcool à coucher−8 h,
  écrans à coucher−1 h. L'app compagnon raffine le coucher via
  `Weather.getSunset()` et le stress via `SensorHistory.getStressHistory()`.
- **NSDR** : 4 moments du livre avec durées **30 min le matin, 20 min
  l'après-midi, 10 min avant séance, 10 min le soir** (10–30 min dans le livre ;
  le 10 min avant séance est un choix de design, pas une donnée source).

**Limite structurelle confirmée par le binaire de debug** : `Toybox.Attention`
est interdit dans une watch face — aucun buzz n'est possible depuis le cadran.
L'app compagnon `companion/` apporte le buzz, mais ayant un app ID distinct elle
ne partage pas `Application.Storage` avec le cadran : le score d'habitude reste
propre à la face. Le simulateur ne permet pas de vérifier le buzz physique ni
l'appui du bouton : `notMeasured`.

Preuves visuelles : `docs/screens/` (12 captures relues, 8 messages + 4
variantes). `docs/popup-design-v2.png` est conservée comme témoin de l'ancien
découpage tronqué, avant correction de `wrapText`.

## App compagnon — buzz des protocoles

`companion/` est une **watch-app** Connect IQ séparée (`type="watch-app"`, app
ID dédié) qui fournit le retour haptique impossible depuis le cadran :

- `Background.registerForTemporalEvent()` chaîné : un seul événement actif,
  replanifié vers le prochain créneau **exact**, avec gestion de minuit et des
  fenêtres solaires ;
- un seul buzz court `VibeProfile(60, 120)` par jour et par slot, marqué comme
  fait **après** la tentative (pas avant), avec traçabilité « dernier événement »
  et « dernier buzz » dans le diagnostic ;
- si la vibration directe depuis le background est indisponible, l'app demande
  son réveil via `Background.requestApplicationWake()` — **le SDK affiche une
  confirmation à l'utilisateur**, ce réveil n'est donc jamais silencieux — puis
  vibre et ouvre un popup riche au premier plan ;
- algorithmes raffinés : `Weather.getSunset()`, tendance de stress sur 1 h et
  Body Battery via `SensorHistory`, objectif de pas pondéré par le temps écoulé ;
- **vue diagnostic centrée** : 15 métriques en deux colonnes, ✔ vert / ✘ rouge,
  avec ligne « Event » et « Buzz » pour distinguer planning et vibration ;
- **long appui milieu gauche** (`onMenu`) ouvre le panneau de test ; dans ce
  panneau, un long appui programme un auto-test de 10 s et revient au cadran ;
- **appui court haut droit** sur le diagnostic : buzz de test immédiat ;
- **popup de l'app** : retourné directement par `getInitialView()` quand un
  événement est en attente, pour que le delegate soit attaché dès l'ouverture.
  Appui court haut droit = accuser et fermer ; bas droit et menu = fermer ;
  fermeture automatique après 25 s par un `Timer`.
- **cadran** : `WatchFaceDelegate.onPress()` est un **appui maintenu** — un appui
  court n'est pas délivré à une watch face. Appui long = accuser puis fermer le
  popup. Le FR955 **est** tactile (`Devices/fr955/simulator.json` : `isTouch: true`,
  `tap → onSelect`) ; `WatchFaceDelegate.onTap()` est documenté comme disponible
  uniquement en mode configuration du cadran. Le spike de tapped normal est
  décrit dans `docs/architecture/CURRENT-STATE.md`.

```bash
cd companion && ./build.sh
# -> companion/bin/bigdigits-buzz-fr955.prg
```

Copier les deux binaires dans `GARMIN/Apps/` : `bigdigits-fr955.prg` (cadran)
et `bigdigits-buzz-fr955.prg` (app), puis lancer **Protocoles Buzz** une fois
pour enregistrer le premier événement temporel. Le buzz n'est pas vérifiable
dans le simulateur Connect IQ (`notMeasured`); seule la compilation prouve
l'enregistrement de `Attention` auprès du SDK.

## Scripts de release et de vérification

- `./verify.sh` — enchaîne `git diff --check`, les trois builds stricts `-l 3`,
  le contrôle des captures et de `RELEASES.md`. Le gate tests reste `partiel`
  tant que le simulateur ne peut pas exécuter `monkeydo -t`.
- `./release.sh` — rebuild les trois `.prg` et écrit `RELEASES.md` avec les
  SHA-256 et l'état de l'arbre Git.
- `USB_DEV=/dev/bus/usb/XXX/YYY ./deploy.sh` — monte la montre via MTP,
  sauvegarde chaque `.prg` existant en `.prev.<horodatage>`, copie les binaires,
  vérifie les tailles puis démonte. Le rollback consiste à recopier le `.prev`.

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

## Critères de protocoles et architecture

Les seuils « assez / pas assez » sont documentés et sourcés dans
`docs/architecture/protocol-criteria-from-book.md` (extraits du livre
*Protocols*, avec identifiants de chunks). Les données réelles utilisées pour
les confronter sont archivées dans `docs/architecture/watch-data-2026-11-25.md`.
Le comparatif des projets équivalents et l'architecture retenue sont dans
`docs/veille/2026-11-25-comparatif-protocoles-architecture.md` et
`docs/architecture/DECISIONS/ADR-0009…0010.md`.

### Timing et interaction des notifications

Le moteur de timing est un module pur partagé (`shared/Timing.mc`) compilé dans
la face, l'app et les tests. Il applique les seuils du livre aux données réelles
quand elles existent (événements coucher/lever, pas, stress, Body Battery) et
repli sur `UserProfile` sinon (`eventConfidence()` exige 3 couchers sur 7 jours).
Les créneaux calculés remplacent les heures codées en dur. Si un **réveil est
programmé** (`wakeTime` dans l'app, `upcomingWakeTime` sur le cadran), le coucher visé est `réveil − 8 h`, les écrans
s'arrêtent **1 h avant** et la caféine s'arrête 8 h avant ; sinon les heures
réelles des événements coucher/lever servent de référence. Un réveil au milieu
de la nuit (≤ 04 h 30 ou décalé de plus de 2 h) est signalé comme réveil de
match avec un rappel NSDR. La lumière utilise le **lever et le coucher du
soleil** (`Weather.getSunrise/getSunset`, repli NOAA sur le cadran). Le pas est
déclenché quand le rythme requis dépasse 100 pas/min. Le NSDR combine cinq
signaux — dette 7 nuits, dernière nuit, régularité du coucher, stress et Body
Battery — pour choisir 10, 20 ou 30 min et le meilleur créneau (ADR-0013).

Sur le FR955, **il n'y a pas d'écran tactile** et `WatchFaceDelegate.onPress()`
est un appui maintenu : le cadran ne reçoit jamais d'appui court. Le mapping
retenu (ADR-0012) est donc :

- **appui long sur le cadran** : coche la case du jour et ferme le popup ;
- **accusé rapide** : uniquement dans l'app compagnon (`PopupDelegate.onPress`),
  sans cocher, ou par expiration automatique ;
- **durée d'affichage** : 1 h maximum pour un rappel protocole, 10 s pour le
  panneau de test ; une seule notification par catégorie et par jour ;
- **apprentissage** : validé tard → rappel 15 min plus tôt le lendemain, accusé
  rapide → 15 min plus tard, expiration → inchangé.

Vérification : `./verify.sh` (diff, trois builds `-l 3`, **22 tests unitaires**,
captures, provenance `RELEASES.md`). Le pont face ↔ compagnon par complications
reste un **spike** : la latence de publication sur `fr955` est `notMeasured`.

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
