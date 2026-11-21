# Revue de sécurité du front (auto-revue)
Portée : branches `feat/p05-admin-skeleton`, `feat/fr02-admin-categories`, `feat/p04-mobile-l10n`. Auteur de la revue = auteur du code (Claude) : **ne remplace pas la revue croisée** exigée par PROTOCOL.md.

| # | Constat | Gravité | État |
|---|---|---|---|
| 1 | Adresse de l'API : repli sur `http://localhost` même en production | Moyenne | Corrigé : en production, pas de repli ; toute requête échoue (`ConfigError`) si l'adresse manque ou n'est pas en HTTPS. Testé |
| 2 | Aucun en-tête de sécurité (clickjacking, sniffing, origines autorisées) | Moyenne | Corrigé : CSP, X-Frame-Options, nosniff, Referrer-Policy, HSTS, Permissions-Policy ; vérifiés sur le serveur réel |
| 3 | Session non fermée côté interface sur 401 `UNAUTHENTICATED` / `TOKEN_REVOKED` | Moyenne | Corrigé : jetons effacés et retour à la connexion. Testé |
| 4 | Appel d'une route authentifiée sans session envoyé au serveur | Faible | Corrigé : refus local |
| 5 | Serveur factice à l'écoute sur toutes les interfaces, corps de requête non borné | Faible | Corrigé : 127.0.0.1, 64 Ko |
| 6 | Workflow CI sans `permissions` | Faible | Corrigé : `contents: read` |
| 7 | Un fichier de build était suivi par git dans la branche mobile | Faible | Corrigé |
| 8 | CSP avec `'unsafe-inline'` pour les scripts (exigé par Next.js sans nonce) | Moyenne | Ouvert : OP-18 |
| 9 | Tout utilisateur connecté atteint les écrans admin (le serveur répond 403) | Moyenne | Ouvert : OP-16 |
| 10 | Actions GitHub épinglées par étiquette (`@v4`), pas par empreinte | Faible | Ouvert : OP-18 |

Contrôles sans constat : aucun secret dans les trois branches ; aucun `localStorage`, `innerHTML`, `eval` ou `console` dans l'application ; jetons en mémoire seulement ; texte du serveur jamais affiché ; paramètres d'URL encodés ; `npm audit` sans alerte ; textes d'aide mobiles cohérents avec EP-007/EP-008.
