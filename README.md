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
└── haproxy/
    └── haproxy.cfg
```