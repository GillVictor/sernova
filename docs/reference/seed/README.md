# Données de départ

`congo-localities.csv` : dix villes au niveau ville (colonne `district` vide). Les coordonnées sont indicatives : la tâche S1-T2 doit les vérifier ou les compléter (GeoNames ou OpenStreetMap) et passer `coord_status` à `verifie`. Les quartiers de Brazzaville et de Pointe-Noire seront ajoutés dans un fichier séparé `congo-districts.csv` (même format, colonne `district` renseignée) quand la liste sera fournie.
Les noms sont conservés avec leurs accents ; la recherche utilise la clé normalisée `villeCle` (minuscules, sans accents ni tirets).
