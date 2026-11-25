# ADR-0007 — Release traçable et réversible

- Statut : proposé
- Date : 2026-11-25
- Décideurs : propriétaire du projet
- Drivers : traçabilité, PRA

## Contexte

-w warnings-only (build.sh:28), 0 tag, commit 62810e15c2 du 2026-11-24, MTP sans copie de sécurité (README.md:240-245).

## Options envisagées

| Option | Avantages | Inconvénients | Coût | Réversibilité |
|---|---|---|---|---|
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |
| undefined | undefined | undefined | undefined | undefined |

## Décision

Retenir A. B/C rejetés.

## Conséquences

- Positives : provenance ; rollback ~30 s
- Négatives acceptées : discipline de tag
- À surveiller : clés ignorées (.gitignore:2-4)

## Preuves

- `build.sh:22-28`
- `.gitignore:2-4`
- `README.md:236-238`

## Révision

Au premier incident de déploiement.
