# Réplication MySQL locale (WSL)

Deux instances indépendantes : primaire sur `127.0.0.1:3307` et réplique en lecture seule sur `127.0.0.1:3308`. Le serveur XAMPP sur 3306 n'est pas modifié. Cette configuration est destinée à un test local, pas à la production.

Après installation des paquets Ubuntu `mysql-server` et `mysql-client`, initialiser une seule fois depuis PowerShell :

```powershell
wsl -e bash /mnt/d/Clone_github/Clustering/mysql-replication/setup.sh
```

Les données et les identifiants root générés sont enregistrés dans `~/.local/share/clustering-mysql` dans WSL. Le script refuse d'écraser ce dossier s'il existe déjà. En cas d'échec, consulter les journaux et conserver le dossier pour diagnostic.

Pour redémarrer ou arrêter les instances :

```powershell
wsl -e bash /mnt/d/Clone_github/Clustering/mysql-replication/start.sh
wsl -e bash /mnt/d/Clone_github/Clustering/mysql-replication/stop.sh
```

Depuis un shell WSL, vérifier la réplication :

```bash
mysql --defaults-extra-file="$HOME/.local/share/clustering-mysql/client.cnf" --socket="$HOME/.local/share/clustering-mysql/replica/mysql.sock" -e 'SHOW REPLICA STATUS\G'
```

Les champs `Replica_IO_Running` et `Replica_SQL_Running` doivent être à `Yes`. Les serveurs Spring Boot enregistrent les messages sur la primaire avec un compte limité à la table `clustering.messages`. Pour créer ce compte après une nouvelle installation, exécuter `wsl -e bash /mnt/d/Clone_github/Clustering/mysql-replication/provision-app.sh`. La réplication est asynchrone : la réplique peut avoir du retard et ne remplace pas une sauvegarde.

connection primary:
mysql --defaults-extra-file="$HOME/.local/share/clustering-mysql/client.cnf" \
  --socket="$HOME/.local/share/clustering-mysql/primary/mysql.sock"
connection replication:
mysql --defaults-extra-file="$HOME/.local/share/clustering-mysql/client.cnf" \
  --socket="$HOME/.local/share/clustering-mysql/replica/mysql.sock"
