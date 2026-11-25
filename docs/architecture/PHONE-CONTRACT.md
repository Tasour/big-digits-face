# Contrat binaire montre ↔ téléphone — v1

- Statut : **figé pour la version 1**
- Date : 2026-11-25
- Décision liée : `docs/architecture/DECISIONS/ADR-0014-deux-boucles-telephone.md`
- Implémentation : `shared/Timing.mc` (format), `companion/source/BuzzApp.mc` (transport)

Le téléphone n'est **pas** sur le chemin critique d'un rappel. La montre décide
seule ; le téléphone reçoit un instantané une fois par jour et renvoie au plus
quelques corrections bornées. Si le téléphone est absent, rien ne change.

## 1. Règles communes

| Règle | Valeur |
|---|---|
| Boutisme | little-endian, sur tous les champs |
| Entier | 16 bits non signé, `0xFFFF` = **absent** |
| Absence | `0xFFFF`, décodé `-1` ; jamais `0` |
| Horodatage | secondes epoch UTC en 32 bits signé (valide jusqu'en 2038) |
| Intégrité | CRC-16/CCITT-FALSE (polynôme `0x1021`, init `0xFFFF`) sur tout sauf le CRC |
| Version | `1` en octet 0 ; toute autre version est **rejetée** |
| Longueur | octet 1 répète la taille totale, contrôle anti-troncature |
| Transport | BLE `Communications` uniquement, **au premier plan**, aucun URL ni cloud |
| Budget | 62 octets par instantané, 40 octets par correction, ≤ 32 clés |

## 2. Montre → téléphone : instantané (`62` octets)

| Offset | Taille | Champ | Unité |
|---:|---:|---|---|
| 0 | 1 | `version` | `1` |
| 1 | 1 | `len` | `62` |
| 2 | 2 | `seq` | compteur monotone, remis à 1 après 65 534 |
| 4 | 2 | `day` | jour local (epoch-day modulo 65 534) |
| 6 | 4 | `ts` | secondes epoch de l'envoi |
| 10 | 2 | `flags` | bit 0 = réveil de nuit détecté |
| 12 | 48 | 24 champs `uint16` | voir ci-dessous |
| 60 | 2 | `crc16` | CRC des octets 0 à 59 |

Champs, dans l'ordre, **jamais renumérotés** :

| # | Clé | Unité | Absence |
|---:|---|---|---|
| 0 | `alarm` | minute du jour | `-1` si aucun réveil |
| 1 | `bedTarget` | minute du jour | |
| 2 | `screensOff` | minute du jour | |
| 3 | `caffeine` | minute du jour | |
| 4 | `bedMean` | minute du jour (moyenne circulaire) | |
| 5 | `wakeMean` | minute du jour (moyenne circulaire) | |
| 6 | `bedCount` | nombre de couchers réels sur 7 j | |
| 7 | `lastNight` | minutes dormies | `-1` |
| 8 | `debt` | minutes de dette sur 7 nuits | |
| 9 | `bedSD` | écart-type circulaire, minutes | `-1` si < 2 couchers |
| 10 | `stressZ100` | z robuste × 100, borné à 0 | |
| 11 | `bb` | Body Battery 0–100 | `-1` |
| 12 | `steps` | pas du jour | `-1` |
| 13 | `goal` | objectif de pas | `-1` |
| 14 | `sunrise` | minute du lever du soleil | `-1` |
| 15 | `sunset` | minute du coucher du soleil | `-1` |
| 16 | `nsdrScore` | score 0–5 | |
| 17 | `nsdrMin` | 0, 10, 20 ou 30 | |
| 18 | `verdict` | 0 aucun, 1 repos suffisant, 2 repos nécessaire | |
| 19 | `reasonCode` | table §3 | |
| 20 | `slot` | créneau déclencheur (`700`, `2100`, `2400`…) | `-1` |
| 21 | `habitBits` | bit *i* = coucher enregistré il y a *i* jours | |
| 22 | `reserved1` | `-1` | réservé |
| 23 | `reserved2` | `-1` | réservé |

## 3. Codes de raison (immuables)

| Code | Sens |
|---:|---|
| 0 | aucun |
| 1 | lumière du matin |
| 2 | marche après le repas |
| 3 | arrêt des stimulants |
| 4 | coucher du soleil |
| 5 | rythme de pas insuffisant |
| 6 | NSDR |
| 7 | écrans éteints |
| 8 | stress aigu |
| 9 | réveil de nuit |

Renuméroter un code invalide l'historique du téléphone : la table est figée.

## 4. Téléphone → montre : corrections (`40` octets)

| Offset | Taille | Champ | Unité |
|---:|---:|---|---|
| 0 | 1 | `version` | `1` |
| 1 | 1 | `len` | `40` |
| 2 | 2 | `seq` | |
| 4 | 4 | `ts` | secondes epoch du calcul |
| 8 | 26 | 13 champs `uint16` | voir ci-dessous |
| 34 | 4 | `exp` | expiration du verdict, secondes epoch |
| 38 | 2 | `crc16` | CRC des octets 0 à 37 |

| # | Clé | Bornes | Absence |
|---:|---|---|---|
| 0 | `needMin` | 0–1440 | `-1` |
| 1 | `sleepScore` | 0–100 | `-1` |
| 2 | `debt7` | 0–5000 | `-1` |
| 3 | `bedSD` | 0–720 | `-1` |
| 4 | `hrvBase` | 0–200 | `-1` |
| 5 | `bbBase` | 0–100 | `-1` |
| 6 | `nsdrMin` | 0, 10, 20, 30 | `-1` |
| 7 | `nsdrAt` | 0–1439 | `-1` |
| 8 | `verdict` | 0–2 | `-1` |
| 9 | `reasonCode` | 0–15 | `-1` |
| 10 | `confidence` | 0–100 | `-1` |
| 11 | `reserved` | `-1` | réservé |
| 12 | `reserved` | `-1` | réservé |

## 5. Validation à la réception

Les contrôles sont appliqués **dans cet ordre** ; le premier échec rejette la
trame entière, sans appliquer de champ partiel :

1. type : `ByteArray` ou tableau de nombres uniquement ;
2. taille exacte (`40`) ;
3. `version == 1` ;
4. `len == 40` ;
5. CRC identique ;
6. `exp > maintenant` ;
7. bornes de chaque champ ;
8. cohérence `nsdrMin` avec la plage du livre (0, 10, 20, 30).

Une correction reçue est stockée avec son expiration. Dès que `exp` est
dépassée, le calcul local reprend : un seuil périmé ne pilote jamais un rappel.

## 6. Ce qui n'est jamais transmis

Aucun identifiant, aucun jeton, aucun nom, aucune position brute, aucune donnée
de santé au-delà des agrégats ci-dessus. Le payload est un état de décision, pas
un journal de santé.

## 7. Limite mesurée

La moitié « téléphone → montre » exige une application téléphone qui parle le
protocole Garmin Connect IQ. Sans elle, seule la moitié montre → téléphone est
prouvable : le format, le CRC et le décodage sont testés (19 tests unitaires),
le transport BLE réel reste **`notMeasured`**.
