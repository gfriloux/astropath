# Tests manuels — v0.1.0 (couche données)

> Exécutés par l'utilisateur en validation finale. La couche données n'a pas d'UI ;
> ces tests confirment surtout que le **schéma notmuch supposé** correspond à la vraie base.

## 1. Schéma notmuch réel vs supposé

Dans le dev shell (`nix develop`) :

| Action | Résultat attendu | OK |
|---|---|---|
| `notmuch search --format=json 'tag:unread' \| head` | Objets avec les clés `thread, timestamp, date_relative, matched, total, authors, subject, query, tags` | ☐ |
| `notmuch count 'tag:unread'` | Un entier | ☐ |
| `notmuch show --format=json 'tag:unread' \| head` | Arbre fil/messages avec `headers` (Subject/From/Date), `body`, `tags` | ☐ |

Si une clé diffère, ajuster `src/model/threads.js` + le golden correspondant.

## 2. Transform sur données réelles (essai facultatif)

| Action | Résultat attendu | OK |
|---|---|---|
| Script d'essai : `parseSearch` sur la sortie réelle de `notmuch search` | Liste de fils cohérente (expéditeur, sujet, compteur, tags, unread/flagged corrects) | ☐ |
| Fil avec `tag:flagged` | `flagged: true` dans le modèle | ☐ |
| Fil multi-messages | `total` = nombre de messages du fil | ☐ |

## 3. Goldens

| Action | Résultat attendu | OK |
|---|---|---|
| `just test` | Tous les goldens passent | ☐ |
| `just bless` après un changement intentionnel | Goldens régénérés, diff relu et conforme | ☐ |
