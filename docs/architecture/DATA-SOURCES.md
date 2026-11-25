# Sources de données — big-digits-face (2026-11-25)

Matrice vérifiée dans le SDK Connect IQ 9.3.0 installé. `face` = watch face,
`app` = watch-app. Aucune donnée n'est inventée : ce qui n'existe pas est marqué `absent`.

| Besoin | API réelle | Face | App | Usage cible |
|---|---|---|---|---|
| Heure locale | `Time/Gregorian.info(Time.now(), FORMAT_SHORT)` | oui | oui | créneaux |
| Réveil typique configuré | `UserProfile.upcomingWakeTime`, `wakeTime` | oui | oui | repli |
| Dodo typique configuré | `UserProfile.upcomingSleepTime`, `sleepTime` | oui | oui | repli |
| Événement réel réveil | `Background.registerForWakeEvent()`, `ServiceDelegate.onWakeTime()` | non | oui | Réveil, Pas |
| Événement réel dodo | `Background.registerForSleepEvent()`, `ServiceDelegate.onSleepTime()` | non | oui | Stimulants, Écrans, Pas |
| Durée de sommeil mesurée | **absente de l'API CIQ 9.3.0** | — | — | déduite des événements sleep/wake |
| Score de sommeil (0–100) | complication native `COMPLICATION_TYPE_SLEEP_SCORE` | **non supporté sur fr955** (`simulator.json` ne déclare que `time`) | non | `notMeasured` — remplacé par durée déduite des événements |
| Stress instantané | `ActivityMonitor.Info.stressScore` | oui | oui | Calme, NSDR |
| Historique stress | `SensorHistory.getStressHistory()` | non | oui | Calme, NSDR |
| Body Battery instantané | complication native `COMPLICATION_TYPE_BODY_BATTERY` | oui | non | NSDR, Calme |
| Historique Body Battery | `SensorHistory.getBodyBatteryHistory()` | non | oui | NSDR, Calme |
| Récupération (minutes) | complication native `COMPLICATION_TYPE_RECOVERY_TIME` | oui | non | Calme, NSDR |
| FC, SpO2, température | `SensorHistory.getHeartRateHistory()`, `getOxygenSaturationHistory()`, `getTemperatureHistory()` | non | oui | NSDR, Calme |
| Coucher solaire | `Weather.getSunset()` (téléphone), NOAA local en repli | NOAA | Weather + NOAA | Soleil |
| Pas / objectif | `ActivityMonitor.Info.steps`, `stepGoal` | oui | oui | Pas |
| Calories, étages, minutes actives | `ActivityMonitor.Info` | oui | oui | contexte |
| Position | `Position.getInfo()` (permissions) | oui (`getInfo`) | oui | NOAA |
| Envoi téléphone | `Communications.transmit()` — **supporté sur `Forerunner® 955`** | non | oui | instantané 62 octets, 1/jour |
| Réception téléphone | `Communications.registerForPhoneAppMessages()` | non | oui | corrections 40 octets |
| Accusé d'envoi | `Communications.ConnectionListener.onComplete/onError()` | non | oui | états `ok` / `attente` / `abandon` |

## Champs horodatés exploitables pour le timing (2026-11-25)

| Champ | Source réelle | Portée | Confiance |
|---|---|---|---|
| `sleep.bed.<jour>` | `Background.registerForSleepEvent()` | app compagnon | événement réel, 1/jour |
| `sleep.wake.<jour>` | `Background.registerForWakeEvent()` | app compagnon | événement réel, 1/jour |
| Durée de nuit | différence bed→wake | app compagnon | déduite, pas un score natif |
| `ActivityMonitor.Info.steps` / `stepGoal` | capteur | face + app | réel |
| `stressScore` + `getStressHistory()` | capteur | face (instantané) / app (1 h) | réel |
| `getBodyBatteryHistory()` | capteur | app | réel |
| `upcomingWakeTime` / `sleepTime` | `UserProfile` | face + app | **repli**, pas une mesure |
| `Weather.getSunset()` | téléphone + NOAA | app | réel si position dispo |
| Appui long | `WatchFaceDelegate.onPress()` = « touch and hold » (SDK 9.3.0) | face | seul geste reçu par le cadran |
| Appui court | `BehaviorDelegate.onPress()` | app compagnon | seul geste qui accuse sans cocher |

Le FR955 **est tactile** : `~/.Garmin/ConnectIQ/Devices/fr955/simulator.json`
déclare `display.isTouch = true` et `tap → onSelect` (gestes `hold`, `release`,
swipes inclus). En revanche `WatchFaceDelegate.onTap()` est documenté
« Only available in WatchFace config mode » (`WatchFaceDelegate.html`), tandis
que `onPress()` est « touch and hold ». Le mapping exact fait l'objet d'un spike
documenté dans `CURRENT-STATE.md` ; tant qu'il n'est pas prouvé, l'accusé rapide
reste disponible dans l'app compagnon ou par expiration à 1 h.

## Contraintes

- `Application.Storage` est propre à un app ID : aucun partage face ↔ app.
- Une watch-app ne peut pas s'abonner aux complications natives ; seule la face le peut.
- Le pont prévu est une complication custom publiée par l'app (`id0` texte, `id1` slot) et lue par la face, avec repli sur les chaînes compilées.
- Les événements temporels background ont un minimum de **5 minutes** (`Background.html:1707`).
- Les événements sleep/wake background sont enregistrés séparément et ne comptent pas dans ce minimum.
- Le simulateur exige un verrou `~/Sim-tasour` valide ; un PID mort provoque `exit(255)` silencieux.
