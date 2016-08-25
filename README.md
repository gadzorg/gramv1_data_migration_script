# gramv1_data_migration_script

## Fonctionnement

1. Récupère la liste des comptes du LDAP GrAM
2. Ajoute un UUID à chaque compte (pas de vérification de l'unicité)
3. Ajoute l'identifiant Google numérique à la place de l'adresse mail principal
4. Crée un CSV a destination du script d'import du gram2
5. Crée un CSV à destination du script d'import du site SOCE
6. Enregistre les UUID dans les comptes LDAP

Les CSV sont créés dans le dossier `/OUT`

## Installation

Créer le fichier config.yml à la racine
Le fichier config.tempalte.yml est disponible :

``` yaml
default: &default  
  ldap_host: localhost
  ldap_port: 389
  ldap_base: ou=gram,dc=gadz,dc=org
  ldap_bind_dn: 
  ldap_password: 
no_env:
  <<: *default
```

Installer les dépendances : `bundle install`

Ajouter le fichier `client_secret.json` dans le dossier `/secrets` (Disponible via la console developer Google)

Lancer le script : `bundle exec ruby ./run`

Au premier lancement, un code d'authorisation google est demandé. Suivre les instructions affichées dans la console pour l'obtenir.
