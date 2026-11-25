# ADR-0009 — Seuils du livre comme plancher, baseline personnelle comme adaptation

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : fiabilité des messages, honnêteté scientifique, 100 % local

## Contexte

Les messages « assez / pas assez » doivent reposer sur des critères explicites.
Le corpus *Protocols* fournit des seuils durée (7–9 h de sommeil, 5–10 min de
lumière matinale, 8–10 h sans caféine, 10–30 min de NSDR, 7 000/10 000 pas,
1–3 soupirs physiologiques) mais **aucun seuil chiffré de score de sommeil,
de Body Battery ni de stress** (`protocol-criteria-from-book.md`). Les données
réelles archivées montrent 3 nuits sur 7 sous 7 h et un dodo moyen à 23 h 24
(`watch-data-2026-11-25.md`). Le code actuel utilise `sleepTime < 420 min`
(`companion/source/BuzzApp.mc:195-200`), un objectif de pas pondéré par la
fenêtre d'activité (`BuzzApp.mc:214-229`) et un seuil Body Battery à 30
(`BuzzApp.mc:311-313`) dont l'origine n'est pas le livre.

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| **A. Seuils du livre codés en dur** | traçable, reproductible, testable ; aucune donnée supplémentaire | ignore la variabilité individuelle ; le seuil caféine 8 h est la borne tardive | 1 | immédiate |
| **B. Baseline personnelle seule** (médiane/MAD ou robust-Z sur 28 j) | s'adapte au porteur ; détecte l'anomalie relative | nécessite 28 j d'historique ; peut valider 5 h de sommeil comme « normal » ; contraire au livre | 4 | moyenne |
| **C. Plancher du livre + delta personnel** | respecte le livre et corrige le biais individuel | deux sources à réconcilier ; plus de tests | 3 | moyenne |

## Décision

Retenir **C** en cible, livrable par étapes : **A immédiatement** (les seuils du
livre deviennent la source de vérité des messages et sont documentés), puis
**C** en P1 quand une baseline fiable sera disponible hors montre. **B seul est
rejeté** : un baseline peut normaliser une privation chronique, ce qui contredit
le livre. Le seuil Body Battery à 30 reste explicitement une **heuristique
locale**, jamais présentée comme une recommendation de *Protocols*.

## Conséquences

- Positives : chaque message est justifiable par une phrase sourcée ; les
  heuristiques sont étiquetées ; aucune mesure inventée.
- Négatives acceptées : deux niveaux de seuils à maintenir pendant la
  transition ; le delta personnel exigera un historique et des tests.
- À surveiller : dérive entre les seuils compilés dans la face et la table de
  seuils calculée hors montre ; `notMeasured` pour le ressenti au réveil.

## Preuves

- `docs/architecture/protocol-criteria-from-book.md` — extraits `chunk_101`,
  `chunk_252`, `chunk_298`, `chunk_361`, `chunk_366`, `chunk_399`, `chunk_414`,
  `chunk_464`, `chunk_574`, `chunk_576`, `chunk_578`, `chunk_904`, `chunk_914`,
  `chunk_982`, `chunk_1028`, `chunk_209`, `chunk_211`.
- `docs/architecture/watch-data-2026-11-25.md` — 3/7 nuits < 7 h, dodo 23 h 24.
- `companion/source/BuzzApp.mc:195-200,214-229,311-313` — seuils actuels.

## Révision

Si une baseline robuste (≥ 28 j ; 30 j avec exclusion du jour testé dans
healthee 🔴, idée seule) est mesurée sur les
données locales, réévaluer le passage C ; sinon rester en A et le documenter.
