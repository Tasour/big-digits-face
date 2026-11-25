# Benchmark open source — contrôle total d'une Garmin depuis la montre

Date : 2026-11-25. Cible : `/home/tasour/Work/big-digits-face` (cadran Connect IQ
Monkey C pour Forerunner 955 Solar + app compagnon `watch-app`). Lecture seule :
**aucun code applicatif n'a été modifié**, aucun code n'a été copié.

## 1. Fiche cible et requêtes

Besoin : obtenir le maximum de contrôle **depuis la montre** en combinant un
cadran (toujours actif) et une app compagnon (données riches, vibration, menus).
Contraintes : 100 % local, aucun cloud, SDK Connect IQ 9.3.0, écran MIP
260×260, interface en français, installation par MTP sans store.

Mots-clés FR/EN : `contrôle sur la montre / on-device settings`, `cadran Connect
IQ / watch face`, `app compagnon / companion watch-app`, `complications / custom
complication bridge`, `widget lanceur / glance launcher`, `vibration / haptics`,
`Monkey C`, `Forerunner 955 / fr955`.

Requêtes utilisées (5) :

1. `Garmin Connect IQ watch face open source GitHub watch app complication contrôle montre`
2. `github Connect IQ Monkey C open source watch app settings complications watch face configuration`
3. `awesome Garmin Connect IQ open source projects GitHub`
4. `Garmin Connect IQ watch face on-device settings open source monkeyc`
5. `github Connect IQ ComplicationProvider example watch face ComplicationSubscriber monkeyc custom complication`

**Fait SDK vérifié localement** : `AppBase.getSettingsView()` est « only
applicable to watch faces and data fields » (`doc/Toybox/Application/AppBase.html:1647`,
SDK 9.3.0). Le document Vozidlo affirme l'inverse pour les watch-apps : **le SDK
local prévaut**, et cela ouvre la voie d'un vrai menu *Customize* directement sur
le cadran, sans dépendre de l'app pour les réglages.

## 2. Candidats découvertes et shortlist

12 candidats ont été découverts ; 9 ont été retenus (pertinence + licence
vérifiable). Seuil documenté : écarté tout dépôt sans licence prouvée ni lien
direct avec les thèmes « contrôle sur montre », complications, widget ou cadran
MIP. Non retenus : `gregor-srdic/garmin-watchface`, `ISASTO/garmin-watchface`,
`SaladStar/WatchFace1` (licence absente), `klppl/OpenIQ` (distribution, hors
périmètre), `aurpelai/garmin-watchface-template`, `funix83/Funix-Watch` (GPL,
périmètre tutorial), `chrisdfennell/WinterTime-Watchface`, `AutumnTime-Watchface`.

| Candidat | URL | Licence prouvée | Scores S/F/T/M/D | Total |
|---|---|---|---|---|
| garmin/connectiq-apps | https://github.com/garmin/connectiq-apps | Apache-2.0, mais en-têtes « Garmin SDK License Agreement » sur les `.mc` | 5/5/5/5/4 | 4,8 |
| qr/Vozidlo (doc) | https://github.com/qr/Vozidlo/blob/main/docs/best-practices/garmin-connect-iq.md | Apache-2.0 | 4/5/5/3/5 | 4,4 |
| dbist/ridgeline | https://github.com/dbist/ridgeline | Apache-2.0 | 5/4/5/3/4 | 4,2 |
| fevieira27/MoveToBeActive | https://github.com/fevieira27/MoveToBeActive | MIT (icônes Noun Project à part) | 5/4/4/4/3 | 4,1 |
| Anemosx/aion | https://github.com/Anemosx/aion | MIT | 5/4/4/2/4 | 3,9 |
| le-cds/connectiq-faceymcwatchface | https://github.com/le-cds/connectiq-faceymcwatchface | GPL-3.0 | 4/4/4/2/4 | 3,8 |
| AllenBW/garmin-widgets | https://github.com/AllenBW/garmin-widgets | MIT | 4/4/3/3/4 | 3,6 |
| RyanDam/Infocal | https://github.com/RyanDam/Infocal | MIT (polices amont à vérifier) | 5/3/4/4/3 | 3,7 |
| chrisdfennell/Penumbra | https://github.com/chrisdfennell/Penumbra | MIT | 5/3/4/2/3 | 3,4 |

Pondération : similarité 30 %, recouvrement fonctionnel 30 %, stack/contraintes
15 %, maturité 15 %, différenciation 10 %. Scores 1–5. Toutes les pages ont été
consultées le 2026-11-25.

## 3. Fiches d'analyse (synthèses)

- **garmin/connectiq-apps** — échantillons officiels : `Menu2`/`ToggleMenuItem`/
  `Picker` pour réglages sur appareil (`AppSettingsView.mc:9-18,25-50`),
  complications pilotées par propriétés (`TypedFaceView.mc:33-43`),
  logging `LogMonkey` vers `GARMIN/APPS/LOGS`, `Attention.playTone`
  (`LidarThereminController.mc:41-49`), compagnon Android `sendMessage`
  (`SendRoundToDeviceActivity.java:41-54`). 597 ★, 163 forks, dernier push
  2025-01-08. Limite : en-têtes contractuels sur les `.mc` → 🟡 malgré Apache.
- **qr/Vozidlo** — document de 414 lignes, très rigoureux (`[inferred]`,
  `[unverified]`). Apporte la matrice Storage 8 Ko/clé / 128 Ko total,
  `onSettingsChanged()`/`onStorageChanged()`, budgets background 65 536 B et
  30 s, 4 complications max publiées par une watch-app, `:responseType` sur GET
  seulement. 3 ★, 15 commits, `fr955` déclaré. ⚠ Sa phrase sur
  `getSettingsView()` est contredite par le SDK 9.3.0 local.
- **dbist/ridgeline** — cadran Enduro 3, `project.typecheck = 3` à chaque build,
  clés de réglages `never renumber`, layout en fractions + `dc.getFontHeight()`,
  hauteurs de police mesurées (Thai Hot 129, Hot 107, Small 34, Tiny 30,
  XTiny 22), `onPowerBudgetExceeded()`, installation MTP. Apache-2.0 prouvé,
  0 ★, 97 commits, 5 releases. Pas d'app compagnon, anglais seul, SDK 9.2.
- **fevieira27/MoveToBeActive** — `getSettingsView()` (`AnalogApp.mc:51`), menu
  racine à 3 catégories (`AnalogSettingsView.mc:16-32`), un seul délégué
  `onSelect` (`:59-79`), drawables « cycleur » `nextState()` (`:255-470`),
  migration versionnée (`currentVersion=570`), variantes `settings-lowmemory`
  et `excludeAnnotations` pour `fr955`. MIT, 46 ★, 487 commits, 31 releases.
  Icônes The Noun Project hors MIT.
- **Anemosx/aion** — `Theme.mc` centralisé, palette indexée 16 couleurs partagée
  config↔rendu, cache à expirations différenciées (600/300/60/30 min),
  pré-rendu `dialBuffer`, objectifs dynamiques avec repli, `getSettingsView()`
  riche (5 arcs). MIT, `fr955` déclaré, 2 ★, 4 commits, store 100+ downloads.
  Anti-brûlure AMOLED à ne pas transposer sur MIP ; anglais codé en dur.
- **le-cds/connectiq-faceymcwatchface** — configuration sur appareil, relais
  téléphone `CalendarIQService.mc` avec contrat documenté, générateurs Python
  JSON → ressources/constantes, localisation par codes de langue, écriture
  différée au stockage. GPL-3.0 → 🟡. Compagnon Android licence inconnue → ⚪.
  Dernier commit 2021, `fr955` absent.
- **AllenBW/garmin-widgets** — 22 cadrans + 7 paires « Glance + app ». Motif
  clef : `type="widget"` avec `AppBase` à annotations multiples
  (`(:background, :glance)`), `getGlanceView()`/`getInitialView()`/
  `getServiceDelegate()`/`onBackgroundData()` (`BatteryApp.mc`), `WatchMenu`
  à deux niveaux synchronisé avec le phone, `Cues` (tap→bouton avec gardes
  `hasUpDown`/`hasMenu`). MIT, 123 commits en un mois. **Hors MIP explicitement**
  → réimplémentation originale du rendu nécessaire.
- **RyanDam/Infocal** — 8 complications × ~29 options, 16 thèmes, réglages
  **exclusivement via Garmin Connect** (anti-modèle pour notre objectif),
  `onSettingsChanged()` + invalidation du rendu, classe abstraite
  `Complication`, slot « Empty ». MIT, 70 ★, 100K+ downloads, mais dernier
  commit 2020 et dépendance météo OpenWeatherMap → incompatible 100 % local.
- **chrisdfennell/Penumbra** — thèmes clair/sombre, accent indexé, palette
  résolue + icônes noir/blanc (le SDK ne recolorie pas les bitmaps à l'exécution),
  layout en fractions, échelle de polices mesurée `pickFontIndex()`, gardes
  `has :`, dégradation `--`, `fr955` déclaré. MIT, 21 commits, 3 releases.
  Météo dépendante du téléphone ; anglais seul.

Chaque fiche complète a été produite par un agent `veilleur-concurrentiel` le
2026-11-25, en surface publique uniquement. Aucune analyse n'a échoué ; aucun
angle marqué `partiel` sauf les points explicitement notés dans les fiches.

## 4. Matrice des gaps

| Fonctionnalité | Chez eux | Chez nous | Manquant |
|---|---|---|---|
| Réglages sur la montre | Ridgeline, MoveToBeActive, Aion, samples Garmin | diagnostic + tests seulement | vrai `getSettingsView()`/`Menu2` sur le cadran et dans l'app |
| Canal app → cadran | complications (`TypedFaceView.mc:33-43`, Vozidlo §4) | aucun | bridge `ComplicationPublisher`/`Subscriber` |
| Widget lanceur | AllenBW/garmin-widgets | aucun | glance + `System.exitTo()` |
| Vibration traçable | `Attention.playTone` (samples), aucun diagnostic | `Attention.vibrate` + Event/Buzz affichés | validation foreground et anti-doublon prouvés |
| Historique 7 jours | aucun candidat | bits d'habitude dans le cadran seulement | UI historique et synchronisation |
| Thèmes indexés | Aion `Theme.mc`, Penumbra palette duale | couleurs codées en dur par catégorie | module `Theme` unique + catalogue partagé |
| Cache différencié | Aion `isCacheExpired()` | cache solaire seulement | expirations par type de donnée |
| Layout robuste MIP | Ridgeline, Penumbra | géométrie fixe 220×138 | fractions + `getFontHeight()` mesuré sur 955 |
| Typage strict | Ridgeline `typecheck = 3`, AllenBW `-l 3` | warnings tolérés | build bloquant |
| Diagnostic des permissions | aucun | 15 métriques ✔/✘ | **notre différenciateur, à conserver** |

## 5. Idées priorisées

Priorité = impact × (6 − effort), max 25. Quick win = impact ≥ 4 et effort ≤ 2.

| # | Idée | Impact | Effort | Priorité | Source |
|---|---|---|---|---|---|
| 1 | `project.typecheck = 3` bloquant au build (quick win) | 5 | 1 | 25 | Ridgeline `monkey.jungle` |
| 2 | `getSettingsView()` + `Menu2` sur le **cadran** (quick win) | 5 | 2 | 20 | SDK `AppBase.html:1647`, MoveToBeActive `AnalogApp.mc:51` |
| 3 | Matrice Storage/Properties/Settings + limites 8 Ko/128 Ko (quick win) | 5 | 2 | 20 | Vozidlo §4 |
| 4 | Clés de réglages append-only, jamais renumérotées (quick win) | 4 | 1 | 20 | Ridgeline `properties.xml` |
| 5 | Widget `type="widget"` + `AppBase` multi-annotations (quick win) | 5 | 2 | 20 | AllenBW `BatteryApp.mc` |
| 6 | `onSettingsChanged()` → `requestUpdate()` (quick win) | 4 | 1 | 20 | Infocal `HuwaiiApp.mc`, samples Garmin |
| 7 | Cache `config` chargé une seule fois (quick win) | 4 | 2 | 16 | MoveToBeActive `AnalogView.mc:17` |
| 8 | Module `Theme` indexé partagé config↔rendu (quick win) | 5 | 2 | 16 | Aion `Theme.mc:102` |
| 9 | Layout en fractions + font metrics mesurés (quick win) | 5 | 2 | 16 | Penumbra `View.mc:573-597`, Ridgeline |
| 10 | Dégradation `--` + gardes `has :` (quick win) | 4 | 1 | 16 | Penumbra `View.mc:596,705-710` |
| 11 | Logging local à niveaux + parseur PC (quick win) | 4 | 2 | 16 | samples `barrels/LogMonkey` |
| 12 | `Cues` : tap→bouton avec gardes `hasUpDown`/`hasMenu` (quick win) | 4 | 2 | 16 | AllenBW `Cues.mc` |
| 13 | MTP + build `-r` + SHA-256 + tag signé (quick win) | 4 | 2 | 16 | Ridgeline `RELEASING.md` |
| 14 | Bridge complications app→cadran | 5 | 3 | 15 | Vozidlo §4, `TypedFaceView.mc:33-43` |
| 15 | `WatchMenu` deux niveaux synchronisé | 5 | 3 | 15 | AllenBW `WatchMenu.mc` |
| 16 | Schéma `settings.xml` déclaratif pour slots/thèmes | 5 | 3 | 15 | Infocal `settings.xml` |
| 17 | Buffer statique + coordonnées précalculées | 4 | 3 | 12 | Aion `LayoutManager.mc:95,108` |
| 18 | `onPowerBudgetExceeded()` pour dégrader les secondes | 3 | 2 | 12 | MoveToBeActive `AnalogView.mc:581-600` |
| 19 | Service background à échantillonnage borné | 4 | 3 | 12 | AllenBW `BatteryApp.mc` |
| 20 | Classe abstraite `Complication` + sous-classes | 5 | 4 | 10 | Infocal `source/complication/` |

## 6. Directions d'amélioration

- **UX** : menu *Customize* sur le cadran, `Menu2` ≤ 7 items par écran, libellés
  courts, ✔/✘ conservés comme signature visuelle, indice de touche « appui long ».
- **Architecture** : module `Theme` unique, `DataManager` avec expirations,
  barrel `Lib` partagé entre face/app/widget, bridge de complications pour
  l'état dynamique, stockage append-only versionné.
- **Performance** : typecheck strict, buffer des éléments statiques,
  `onPartialUpdate` avec découpe de zone, une seule lecture des capteurs par
  cycle, budget MIP < 10 % de pixels allumés.
- **Accessibilité** : contraste blanc/noir 21:1, couleur jamais seule porteuse
  de sens, cibles généreuses, repli texte `--` plutôt que champ vide.
- **Distribution** : `.prg` strippé `-r`, SHA-256 publié, installation MTP sans
  store, procédure de suppression/réinstallation documentée quand l'app ID change.
- **Local** : supprimer toute dépendance météo cloud ; utiliser les complications
  Garmin natives ou `Weather` via téléphone uniquement si l'utilisateur le veut.

## 7. Anti-patterns à ne pas reproduire

- Réglages phone-only alors que l'objectif est le contrôle sur la montre
  (Infocal) ou génération de code au lieu d'un menu sur appareil (Facey).
- `getSettingsView()` documenté à l'envers (Vozidlo) : toujours revérifier dans
  le SDK installé (`AppBase.html:1647`).
- Anglais codé en dur alors que `fre` est déclaré (Aion, Penumbra).
- Renuméroter les clés de réglages ou changer l'app ID : la mise à jour réinitialise
  les préférences et laisse une entrée fantôme (Ridgeline).
- Supposer qu'un build vert prouve la compatibilité appareil (Vozidlo).
- Transposer l'anti-brûlure AMOLED sur un écran MIP (Aion).
- Monolithe de 175 Ko et clés numériques non nommées (MoveToBeActive).
- Cloud météo tiers avec quota (Infocal) ; widget sans port MIP (AllenBW).

## 8. Verdicts de licence et attributions

🟢 **Permissif prouvé** : Vozidlo (Apache-2.0, © 2026 qr), Ridgeline
(Apache-2.0, © 2026 MERA Consulting LLC — attribution à confirmer, pied de
licence non personnalisé), MoveToBeActive (MIT, © 2021 Felipe), AllenBW
garmin-widgets (MIT, © 2026 Allen Manzano-Wight), Infocal (MIT, © 2020 Dam Vu
Duy), Aion (MIT, © 2025 Arnold Unterauer), Penumbra (MIT, © 2026 Christopher
Fennell). Copie autorisée avec attribution ; **aucun code n'a été copié dans ce
benchmark**.

🟡 **Copyleft ou conditions contractuelles** : Facey McWatchface (GPL-3.0) ;
samples officiels Garmin (Apache-2.0 du dépôt mais en-têtes « Garmin SDK License
Agreement » sur les `.mc`). Arrêt et validation humaine avant tout commit de code.

⚪ **Incertains** : compagnon Android de Facey (licence absente), icônes The Noun
Project de MoveToBeActive, polices amont de Infocal (`warmsound/crystal-face`,
`sunpazed`), 28 autres apps non auditées de AllenBW.

Blocs d'attribution prêts si une réutilisation est décidée plus tard :

```html
<!-- Idée adaptée de Ridgeline (https://github.com/dbist/ridgeline), licence Apache-2.0, © 2026 MERA Consulting LLC. Voir LICENSES.md à la racine du projet. -->
<!-- Idée adaptée de MoveToBeActive (https://github.com/fevieira27/MoveToBeActive), licence MIT, © 2021 Felipe. Voir LICENSES.md à la racine du projet. -->
<!-- Idée adaptée de Aion (https://github.com/Anemosx/aion), licence MIT, © 2025 Arnold Unterauer. Voir LICENSES.md à la racine du projet. -->
<!-- Idée adaptée de garmin-widgets (https://github.com/AllenBW/garmin-widgets), licence MIT, © 2026 Allen Manzano-Wight. Voir LICENSES.md à la racine du projet. -->
<!-- Idée adaptée de Infocal (https://github.com/RyanDam/Infocal), licence MIT, © 2020 Dam Vu Duy. Voir LICENSES.md à la racine du projet. -->
<!-- Idée adaptée de Penumbra (https://github.com/chrisdfennell/Penumbra), licence MIT, © 2026 Christopher Fennell. Voir LICENSES.md à la racine du projet. -->
<!-- Idée adaptée de Vozidlo (https://github.com/qr/Vozidlo), licence Apache-2.0, © 2026 qr. Voir LICENSES.md à la racine du projet. -->
```

Aucune entrée `LICENSES.md` n'a été créée : aucun code n'a été repris.

## 9. Sources datées

Toutes les pages GitHub, API GitHub, pages store et le SDK local ont été
consultés le **2026-11-25**. Références structurantes :

- SDK local : `doc/Toybox/Application/AppBase.html:1633-1647` (`getSettingsView`),
  `doc/docs/Core_Topics/Manifest_and_Permissions.html` (table des permissions par
  type d'app), `doc/Toybox/Complications.html` (Data = String/Number),
  `doc/Toybox/System.html:1353-1407` (`exitTo` depuis watch-app/widget).
- https://github.com/garmin/connectiq-apps ; https://github.com/qr/Vozidlo/blob/main/docs/best-practices/garmin-connect-iq.md
- https://github.com/dbist/ridgeline ; https://github.com/fevieira27/MoveToBeActive
- https://github.com/Anemosx/aion ; https://github.com/le-cds/connectiq-faceymcwatchface
- https://github.com/AllenBW/garmin-widgets ; https://github.com/RyanDam/Infocal
- https://github.com/chrisdfennell/Penumbra

## 10. Limites du scan

- 12 candidats découverts, 9 shortlistés, **pas une revue exhaustive** : les
  requêtes ont ciblé GitHub/awesome-lists et le SDK local ; aucun store payant
  ni avis utilisateur détaillé n'a été consulté.
- Aucun code n'a été exécuté, compilé sous 9.3.0 pour le `fr955`, ni mesuré sur
  la montre. Les chiffres de performance annoncés par les auteurs sont des
  affirmations non reproduites ici.
- Plusieurs dépôts déclarent des SDK 9.2/API 5.x : compatibilité 9.3.0 **non vérifiée**.
- Le rôle exact `ComplicationSubscriber` côté cadran reste à prouver par un spike
  (Vozidlo exclude les cadrans ; les forums rapportent des régressions sous CIQ 7.x).
- Deux analyses ont rencontré des limites d'API GitHub (403) : décompte d'icônes
  de Penumbra et liste complète des releases : `partiel`.
