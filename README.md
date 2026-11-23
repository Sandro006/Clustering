# CLUSTERING

## TEST DU HAPROXY

### STRUCTURE DU PROJET

```
Clustering/
│
├── serveur1/
│   ├── src/main/
│   │   ├── java/com/test/serveur1/
│   │   │   └── Serveur1Application.java
│   │   │
│   │   └── resources/
│   │       ├── application.properties
│   │       └── static/
│   │           └── index.html
│   │
│   └── pom.xml
│
├── serveur2/
│   ├── src/main/
│   │   ├── java/com/test/serveur2/
│   │   │   └── Serveur2Application.java
│   │   │
│   │   └── resources/
│   │       ├── application.properties
│   │       └── static/
│   │           └── index.html
│   │
│   └── pom.xml
│
├── haproxy/
│   ├── haproxy.cfg
│   ├── reload-haproxy.sh   <- valide et recharge HAProxy (appelé par l'API)
│   ├── start-haproxy.sh
│   └── stop-haproxy.sh
```

## CONFIGURER HAPROXY DEPUIS LE NAVIGATEUR

Une page d'administration est disponible sur **http://localhost:8080/config.html**
(elle est servie par les deux serveurs, donc accessible directement sur 8081 et 8082 aussi).

Elle permet de :

- **Paramètres rapides** : port frontend, algorithme d'équilibrage, adresses des backends,
  port/statistiques, persistance de session → « Générer la configuration » remplit l'éditeur ;
- **Éditeur** : modifier `haproxy.cfg` directement, « Recharger depuis le fichier » pour revenir
  à la version sur disque ;
- **Appliquer et redémarrer HAProxy** : sauvegarde l'ancien fichier en `haproxy.cfg.bak`,
  valide la syntaxe (`haproxy -c -f`) puis redémarre HAProxy via WSL. Si la validation échoue,
  l'ancienne configuration est restaurée automatiquement.

### API REST (identique sur les deux serveurs)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/api/haproxy/config` | Lit le contenu de `haproxy.cfg` |
| GET | `/api/haproxy/status` | Informations sur le fichier |
| GET | `/api/haproxy/self` | Port du serveur qui répond (utilisé par la page) |
| POST | `/api/haproxy/config` | Écrit `{ "config": "..." }`, valide et recharge |

La page appelle l'API **directement sur le serveur qui l'a servie** (port 8081 ou 8082)
plutôt que via HAProxy : le rechargement tue momentanément HAProxy, ce qui couperait
sinon la requête en cours (et afficherait une erreur alors que l'application a réussi).

Les chemins peuvent être surchargés dans `application.properties` :
`haproxy.config.path` et `haproxy.reload.script`.

> ⚠️ Le bouton « Appliquer » exécute un redémarrage de HAProxy dans WSL via `wsl -e bash`.
> WSL et HAProxy doivent être installés (voir `start-haproxy.sh`).

## RESEAU WSL

HAProxy tourne dans WSL tandis que les serveurs Spring Boot tournent sur Windows.
La configuration utilise le mode **NAT** (`networkingMode=nat` dans `%USERPROFILE%\.wslconfig`)
avec `localhostForwarding=true` :

- depuis Windows : `http://localhost:8080` et `http://localhost:8404/stats` atteignent WSL ;
- depuis WSL : la passerelle par défaut (ex. `172.22.240.1`) est l'hôte Windows.

`host.docker.internal` n'existe pas en mode NAT dans cette distro : les scripts
`start-haproxy.sh` et `reload-haproxy.sh` le remplacent donc automatiquement par l'IP
de la passerelle dans un fichier généré `haproxy.runtime.cfg`, utilisé par HAProxy.
Le fichier édité reste `haproxy.cfg` (la source de vérité).

Si tu repasses en mode `mirrored`, utilise directement `127.0.0.1:8081/8082` dans
`haproxy.cfg` et dans les valeurs par défaut de `config.html`.