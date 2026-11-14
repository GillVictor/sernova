# Machine à états de la transaction

États : EnAttente, Acceptee, Planifiee, EnCours, Terminee, Confirmee, Cloturee, Annulee, Contestee. Finals : Cloturee, Annulee.
Voie A : création en EnAttente. Voie B : création directe en Acceptee (la proposition retenue vaut engagement).

| De → Vers | Déclencheur | Condition | Effets |
|---|---|---|---|
| (création) → EnAttente | client (voie A) | offre valable | conditions figées, conversation ouverte, prestataire notifié |
| (création) → Acceptee | système (voie B) | proposition retenue | |
| EnAttente → Acceptee | prestataire | réponse sous 48 h | client invité à réserver les fonds |
| EnAttente → Annulee | client, prestataire (refus) ou système | délai dépassé | créneau libéré |
| Acceptee → Planifiee | système ou prestataire | fonds réservés et créneau confirmé | créneau verrouillé |
| Acceptee → EnCours | prestataire | fonds réservés (offres sans créneau) | |
| Acceptee → Annulee | client, prestataire ou système | fonds non réservés sous 24 h | créneau libéré |
| Planifiee → EnCours | prestataire | fonds réservés | |
| Planifiee → Annulee | client, prestataire ou système | prestataire absent après délai + 24 h | remboursement intégral |
| EnCours → Terminee | prestataire | justificatifs ; vente : remise validée par code | fenêtre de 72 h ouverte |
| EnCours → Annulee | administrateur | décision tracée | remboursement total ou partiel (V1 : pas de double accord) |
| Terminee → Confirmee | client, ou système après 72 h | pas de contestation | fonds libérés, évaluations ouvertes |
| Terminee → Contestee | client | dans les 72 h, avec motif | litige ouvert, fonds gelés, conversation en lecture seule |
| Contestee → Cloturee | administrateur | décision rendue | libération, partielle ou remboursement |
| Confirmee → Cloturee | système | évaluations faites ou 7 jours écoulés | reversement effectué |

Chaque transition : vérifie la garde, incrémente `version`, écrit `HistoriqueStatut` et `JournalAction`, émet un événement interne (notifications).

## Paiement (Paiement.statut)
Initie → Reserve (confirmation idempotente du fournisseur) ou Echoue. Reserve → Libere (Confirmee ou décision de litige) ou Rembourse (annulation avec remboursement ou décision). Echoue : nouvelle tentative possible (nouveau Paiement). `Reversement` = libération au prestataire, déclenchée par Confirmee ; montant + commission = montant libéré.

## Livraison
Même matrice. Confirmee = remise validée par le code (haché, expirant, essais limités). La vente liée ne passe à Terminee que lorsque la livraison associée est Confirmee.

## Délais (ParametrePlateforme)
delaiReponsePrestataire 48 h ; delaiReservationFonds 24 h ; toleranceDemarrage 24 h ; fenetreContestation 72 h ; fenetreEvaluation 7 jours.
