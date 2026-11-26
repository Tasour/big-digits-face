# État courant — big-digits-face (2026-11-25)

> Mesures brutes. Un champ sans mesure est `notMeasured`, jamais zéro.

## 1. Cadrage

- Cible : `/home/tasour/Work/big-digits-face`, trois artefacts : face `e9cdc5a8…` (`manifest.xml:3-9`), watch-app `f72c8dae…` (`companion/manifest.xml:3-9`), chrono `8f2c1d4a…` (`chrono/manifest.xml:2-8`).
- Domaine : cadran de lecture instantanée + rappels de protocoles de santé sur FR955 Solar.
- Public : porteur de la montre, français (`manifest.xml:18-21`).
- Contraintes : 100 % local, MIP 260×260, SDK 9.3.0, installation MTP sans store (`README.md:240-245`), zéro réseau.

## 2. Mesures brutes

| Outil / commande | Résultat | Statut |
|---|---|---|
| `tools.arch.profile` | Langages : non détecté ; frameworks : non détecté ; entrées 0 ; persistance 0 ; services 0 ; CI 0 ; adaptateurs absents | `notMeasured` pour Monkey C (outils JS/SQL) |
| `tools.arch.dependency_graph` | 34 fichiers, 0 lien local, 0 cycle ; 10 orphelins dont `README.md` et 9 `*.prg.debug.xml` | heuristique, couplage réel `notMeasured` |
| `tools.arch.api_inventory` | 0 route | cohérent avec 100 % local |
| `tools.arch.data_inventory` | 0 table, 0 migration, 0 signal | aveugle au store clé-valeur Monkey C |
| `tools.arch.budget` | 1 080 611 octets cumulés ; 3 fichiers > 100 Ko, tous `bin/*.prg.debug.xml` | mesuré |
| `wc -l` sur `.mc` | 1 829 lignes (face 871, app 581, chrono 347) | mesuré |
| `stat -c %s` binaires | face 20 972 B ; app 14 588 B ; chrono 10 108 B | mesuré |
| `doc/docs/Device_Reference/fr955.html` | face 131 072 B ; app/widget 786 432 B ; background/glance 65 536 B | mesuré localement |
| `doc/Toybox/Background.html:1707` | < 5 min entre events interdit | mesuré localement |
| `git log -1` | `62810e15c2…` 2026-11-24 ; 0 tag ; 0 SHA-256 publié | mesuré |
| `git status` au 25/11 | `README.md`, `companion/source/BuzzApp.mc`, `source/BigDigitsView.mc` modifiés ; `docs/veille/` non suivi | mesuré |
| `git diff --check` | rc = 0 | mesuré |
| Compilation `-l 3` (copie /tmp, rapport QUALITÉ) | 19 erreurs face, 29 chrono, 37 app = 85 | rapport seul, non rejoué par l'arbitre |
| Suites `(:test)` | 0 test, 0 annotation `(:test)`, 0 `Test.assert` | mesuré |
| `apple-design-gate.sh --file source/BigDigitsView.mc` | 80 règles `notMeasured`, 5 faux positifs P1 | gate DOM inapplicable au `.mc` |
| `System.Stats` instrumenté | absent | CPU/heap/courant `notMeasured` |

## 3. Faits structurels saillants

- `habitBits()` remet les bits à zéro dès qu'un jour est manqué : `source/BigDigitsView.mc:222-234`.
- Planning background : `wait < 1 → 1` minute (`companion/source/BuzzApp.mc:189-190`) et auto-test `Duration(10)` (`:489`), tous deux sous le minimum SDK.
- `dayIndex()` = epoch/86400 (`source/BigDigitsView.mc:218-220`, `companion/source/BuzzApp.mc:26-28`) alors que l'affichage est local.
- `habit.app.day` écrit (`companion/source/BuzzApp.mc:465`) mais jamais lu ; app IDs distincts → Storage étanche.
- Aucun `getSettingsView`, `Complication`, `exitTo` ni `widget` dans les sources (recherche négative).
- `checkStorage()` (`BuzzApp.mc:256-262`) est un oracle in-band sur une clé éphémère, pas sur les clés utiles.
- `docs/screens/app-diagnostic-simulator.png` contient une page web, pas le diagnostic : preuve invalide.

## 4. Outils disponibles / absents

- Disponibles : SDK 9.3.0 (`current-sdk.cfg`), `monkeyc`, `monkeydo`, simulateur `fr955`, `gio`/gvfs pour MTP, outils `arch.*` en mode plan.
- Absents : profileur CPU/courant, oracle haptique matériel, adaptateurs `dependency-cruiser`, `madge`, `knip`, `jscpd`, `import-linter`, `deptrac`, angle `architect-api` au moment du score initial (depuis livré).
- `notMeasured` persistant : buzz physique, appui bouton réel, autonomie, latence `Weather.getSunset()`, rôle exact de `ComplicationSubscriber` sous 9.3.0.
- `apple-design-gate` : applicable aux captures/HTML, **N/A** sur les sources `.mc` (80 règles DOM non mesurables, faux positifs documentés).

## 5. État d'exécution du P0 (2026-11-25, après corrections)

| Action P0 | État | Preuve |
|---|---|---|
| `habitBits()` non destructif | Corrigé ; 7 tests `(:test)` ajoutés (`source/HabitTests.mc`) | build `bin/test-habits.prg` avec `-t` réussi |
| Exécution des tests unitaires | **Bloquée** : le simulateur `fr955` se termine avec le code 255 avant que `monkeydo -t` puisse se connecter | `/tmp/ciq-tests.log` = `Unable to connect to simulator` |
| Planning `Moment` ≥ 5 min, auto-test 10 s retiré | Corrigé | `companion/source/BuzzApp.mc:registerNext()` ; plus aucun `Duration(10)` |
| `getSettingsView()` + `Menu2` sur la face | Ajouté (`source/FaceSettingsView.mc`), deux bascules Secondes/Rappels | `BigDigitsApp.mc:getSettingsView()` |
| `onPress` priorisé | Ajouté ; branche complication = stub explicite en attente du bridge P1 | `source/BigDigitsView.mc:onButtonPress()` |
| Fixture `weekdayLetters` | Extraite en `weekdayLetterFor()` + 2 tests | `source/HabitTests.mc` |
| Gate `-l 3` | **Non vert** : 19 erreurs face, 31 compagnon mesurées après corrections (chrono à remesurer) | `monkeyc ... -l 3` |
| Recapture du diagnostic invalide | **Bloquée** : simulateur indisponible | même cause que les tests |
| Scripts release/deploy `.prev` | Livrés : `release.sh`, `verify.sh`, `deploy.sh`, `RELEASES.md` | `./verify.sh` |

Les trois binaires de production compilent en `-r` sans erreur. **Cause simulator identifiée le 2026-11-25** : fichier verrou de singleton `~/Sim-tasour` périmé, contenant le PID d'un simulateur mort (`142726`). Le binaire sortait donc avec `exit_group(-1)` (code 255) avant toute initialisation. Preuve : `strace -f` (`openat("/home/tasour/Sim-tasour", O_WRONLY|O_CREAT|O_EXCL) = -1 EEXIST`, puis `exit_group(-1)`). Correctif : supprimer le verrou quand aucun processus `bin/simulator` n'est vivant, puis relancer. Le simulateur est de nouveau opérationnel (PID 1064373, log `Debug: SetLayout`). Le JDK 21 local et les flags Qt testés n'étaient **pas** la cause. Commande de rejeu : `strace -f -o /tmp/sim.log <SDK>/bin/simulator <prg>` puis `tail -80 /tmp/sim.log | grep Sim-tasour`.

## 6. Mise à jour du 2026-11-25 (tactile, réveil, lumière, NSDR)

- **Correction matérielle** : l'affirmation « FR955 sans écran tactile » était
  fausse. `~/.Garmin/ConnectIQ/Devices/fr955/simulator.json` déclare
  `display.isTouch = true` et `tap → onSelect`, avec `hold`, `release` et les
  swipes. `README.md`, `DATA-SOURCES.md` et l'ADR-0012 ont été corrigés.
- **Spike `onTap`** : tentative de validation en mode normal sur le simulateur
  `fr955`. La fenêtre du simulateur n'a pas pu être amenée au premier plan de
  façon fiable (plusieurs dispatchers Hyprland refusés, fenêtre masquée), donc
  l'observation est **non concluante = `notMeasured`**. Le SDK documente
  `WatchFaceDelegate.onTap()` comme « Only available in WatchFace config mode »
  (`doc/Toybox/WatchUi/WatchFaceDelegate.html`) et `onPress()` comme
  « touch and hold ». Le mapping retenu reste : appui long = validation sur le
  cadran, accusé court dans l'app compagnon, expiration à 1 h.
- **Réveil programmé** : `UserProfile.Profile.wakeTime` est lu comme réveil
  posé dans l'app ; `upcomingWakeTime` y est signalé non supporté sur `fr955`
  par `-l 3`, mais reste utilisé par le cadran sans avertissement. Coucher visé = réveil − 8 h, écrans off = coucher − 60 min,
  caféine = coucher − 8 h. Un réveil ≤ 04 h 30 ou décalé de > 2 h du lever
  moyen est classé `:match` (hypothèse « match de foot » du porteur, pas une
  mesure) et déclenche un message NSDR dédié.
- **Lumière** : `Weather.getSunrise()` et `getSunset()` sont utilisés dans
  l'app compagnon ; la face garde le repli NOAA symétrique (`1440 − sunset`)
  faute d'accès fiable à `Weather` dans le cadran.
- **NSDR** : score pondéré à cinq signaux (ADR-0013), durée 10/20/30 min dans
  la plage du livre, créneau selon la cause dominante. 30 tests unitaires verts.
- **Gates réels au 2026-11-25** : `verify.sh` vert (G0, G1 trois builds `-l 3`,
  G2 30 tests, G3 captures, G4b parité `Timing.mc`, G4 provenance). Le tableau
  §5 ci-dessus décrit l'état *avant* ces corrections et n'est pas effacé : il
  sert de témoin de l'historique de réparation.

## 7. Lien téléphone (2026-11-25, ADR-0014)

- **Contrat binaire figé** : instantané montre → téléphone de 62 octets,
  corrections téléphone → montre de 40 octets, CRC-16/CCITT-FALSE, absence
  `0xFFFF` décodée `-1`. Détail offset par offset dans
  `docs/architecture/PHONE-CONTRACT.md`.
- **Deux boucles** : la boucle rapide reste entièrement sur la montre (aucun
  appel BLE dans `evaluateSlot`) ; la boucle lente est un envoi quotidien à la première
  ouverture au premier plan et une réponse bornée, appliquée seulement si `exp > maintenant`.
- **Ce qui est prouvé ici** : 19 tests unitaires du format (taille, CRC,
  aller-retour, absence, zéro distinct de l'absence, 9 rejets de corrections),
  soit 50 tests au total, `failed=0, errors=0`. La parité face/compagnon du
  moteur est vérifiée par `scripts/check-timing-parity.sh`.
- **`notMeasured` assumé** : le transport BLE réel (appairage téléphone,
  latence, taux de rejet en usage) ne peut pas être mesuré sans application
  téléphone. Aucun chiffre n'est avancé pour cette moitié.
- **`upcomingWakeTime`** reste signalé non supporté sur `fr955` côté app ;
  l'app lit `wakeTime`, le cadran `upcomingWakeTime` quand disponible.

## 8. Correctif de démarrage en fond (2026-11-25)

- **`Illegal Access (Out of Bounds)` éliminé** : `BuzzApp.onStart()` est aussi
  appelé dans le processus de fond réveillé par `Background.requestApplicationWake()`.
  Il n'appelle plus que les API autorisées en fond (`registerNext`,
  `registerForSleepEvent`, `registerForWakeEvent`). Les mesures d'interface et
  le lien BLE ont été déplacés dans `getInitialView()`, garanti au premier plan.
- Preuve : exécution dans le simulateur fr955 sans entrée `Illegal Access` dans
  `CIQ_LOG.YML`, avec les lignes `BLE envoi` puis `BLE attente` (aucun téléphone
  appairé, comportement attendu).
- **Observabilité** : `bleState()` écrit désormais `System.println("BLE …")`,
  ce qui rend l'état lisible par l'outil MCP `ciq_ble_probe`.
- **Diagnostic relu** : `docs/screens/app-diagnostic-final-watch.png` — 14
  mesures sur deux colonnes et deux lignes d'observabilité, sans chevauchement
  ni débordement hors du cercle.

## 9. Déploiement du 2026-11-25 (preuve MTP)

- Device USB `091e:4fb8`, chemin `/dev/bus/usb/003/016`, montage
  `mtp:host=091e_4fb8_0000cd371feb`.
- Trois binaires copiés puis relus après **démontage/remontage** :
  `bigdigits-fr955.prg` 29 548 octets, `bigdigits-buzz-fr955.prg` 27 948
  octets, `bigdigits-chrono-fr955.prg` 10 108 octets. Tailles conformes à
  `RELEASES.md`.
- `GARMIN/Apps` ne contient aucun autre `.prg` : **aucune ancienne version ni
  face tierce identifiée**, donc rien n'a été effacé. Les dossiers `DATA`,
  `LOGS`, `MAIL`, `SETTINGS`, `TEMP` et `OUT.BIN` sont des fichiers système.
- `CIQ_LOG.BAK` de la montre ne contient que les deux erreurs du 10:21Z
  (avant le correctif de démarrage en fond). Aucune nouvelle entrée depuis le
  déploiement ; l'exécution réelle sur la montre après copie n'est pas
  mesurée ici.

## 10. Diagnostic paginé (correction des FIX-01 à FIX-03)

- Photo réelle du cadran : titre coupé, pied tronqué et bords du bloc hors du
  cercle avec l'ancienne grille à 14 lignes sur deux colonnes.
- Correctif : deux pages d'une seule colonne (7 mesures chacune), titre en
  `FONT_TINY`, largeur du bloc ramenée à 66 % de l'écran et marge verticale de
  10 %. Le module pur `DiagLayout.grid()` est partagé face/compagnon et couvert
  par 4 tests (54 au total).
- Navigation UP/DOWN vérifiée dans le simulateur. Captures relues :
  `docs/screens/diag-page1-watch.png` et `docs/screens/diag-page2-watch.png`.
- Les métriques de police **sur le device** restent `notMeasured` (montre
  débranchée au moment de la mesure) : la marge est donc dimensionnée pour
  résister à des polices plus grandes, pas calibrée sur une valeur inventée.

## 11. Déploiement paginé du 2026-11-26 (preuve MTP)

- Device USB `091e:4fb8` sur `/dev/bus/usb/003/018`, redéploiement des trois
  binaires après le correctif de grille, puis démontage/remontage et relecture.
- Tailles relues conformes à `RELEASES.md` : face 29 836 o, compagnon
  28 316 o, chrono 10 108 o.
- `GARMIN/Apps` ne contient toujours aucun autre `.prg` : rien n'a été effacé.
- `CIQ_LOG.BAK` ne contient que les deux erreurs du 25/11 10:21Z, antérieures
  au correctif de démarrage. Aucune nouvelle erreur enregistrée.

## 12. Validation intégrée au compagnon (2026-11-26)

- **8 sondes pures** dans `shared/FeatureProbes.mc`, copiées à l'identique
  dans le compagnon et vérifiées par `check-timing-parity.sh` avec 5 modules.
- **Menu Validation** (appui long MENU) : lancement global, une entrée par
  sonde, rapport complet, 4 scripts texte et accès au panneau de test.
- **Rapport texte** paginé (UP/DOWN) avec verdicts `ok` / `fail` /
  `notMeasured`, écrit dans `App.Storage` et tracé par `System.println`.
- **DSL restreint** (`ScriptVm.mc`, `ScriptLibrary.mc`) : `CHECK`, `EXPECT`,
  `PRINT`, `LOG`, `SKIP`, `END`. Aucun appel système arbitraire, 32 lignes
  maximum, scripts embarqués à la compilation.
- **MCP** : 25 outils, dont `ciq_validation_report`, `ciq_validation_run`,
  `ciq_validation_script` et `ciq_validation_clear`. Les lignes `VALIDATION`
  du simulateur sont lues dans sa console ; la montre ne les expose pas dans
  `CIQ_LOG`, donc le rapport réel sur device doit être lu à l'écran puis
  communiqué — sinon `notMeasured`.
- **Preuves** : 77 tests verts, G0–G4b verts, captures du menu, d'un rapport
  et d'un script relues.

### Déploiement du 2026-11-26

Device `091e:4fb8` sur `/dev/bus/usb/003/021`, trois binaires copiés puis
relus après remontage : face 36 508 o, compagnon 39 356 o, chrono 10 108 o.
Tailles conformes à `RELEASES.md`. `GARMIN/Apps` ne contient aucun autre
`.prg` : rien n'a été effacé.

Le rapport de validation sur la montre reste **`notMeasured`** tant que
l'app compagnon n'a pas été ouverte sur le device et que son rapport n'a pas
été lu visuellement.

## 13. Score de sommeil et auto-test du cadran (2026-11-26)

- **`ActivityMonitor` n'expose pas le score de sommeil sur `fr955`.** Le SDK
  fournit le type de complication `42` (`COMPLICATION_TYPE_SLEEP_SCORE`), mais
  `ComplicationSubscriber` est interdit aux watch-apps : le score est donc lu
  par le **cadran**, jamais par le compagnon.
- Règle `ADR-0015` : score `< 70` ajoute 10 au stress effectif du cadran (un
  cran), plafonné ; score absent = `-1`, aucun effet. 4 tests dédiés.
- **Auto-test du cadran** : 8 messages, 3 s chacun, traces `FACESELFTEST`,
  écran `RESULTATS` sans habitude ni buzz. Log simulateur archivé dans
  `docs/validation/selftest-face-simulateur-2026-11-26T07-10-57-537Z.txt` :
  8/8, 1 `notMeasured` (coucher solaire non disponible en simulation).
- La capture visuelle du résultat sur le cadran est `notMeasured` : la fenêtre
  du simulateur n'a pas pu être recadrée sur le cadran.
