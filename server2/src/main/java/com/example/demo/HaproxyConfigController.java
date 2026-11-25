package com.example.demo;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * API REST pour lire, modifier et appliquer la configuration HAProxy du test de
 * clustering. Le fichier haproxy.cfg est partage par les deux serveurs : une
 * modification faite depuis l'un ou l'autre est donc visible par HAProxy.
 */
@RestController
@RequestMapping("/api/haproxy")
@CrossOrigin(origins = "*")
public class HaproxyConfigController {

    @Value("${haproxy.config.path:D:/Clone_github/Clustering/haproxy/haproxy.cfg}")
    private String configPath;

    @Value("${haproxy.reload.script:/mnt/d/Clone_github/Clustering/haproxy/reload-haproxy.sh}")
    private String reloadScript;

    @Value("${server.port}")
    private int serverPort;

    /**
     * Renvoie le port de ce serveur. La page s'en sert pour appeler l'API en direct
     * (sans passer par HAProxy, qui est redemarre lors de l'application).
     */
    @GetMapping("/self")
    public ResponseEntity<?> self() {
        return ResponseEntity.ok(Map.of("port", serverPort));
    }

    /** Renvoie le contenu actuel de haproxy.cfg. */
    @GetMapping("/config")
    public ResponseEntity<?> getConfig() {
        Path path = Paths.get(configPath);
        try {
            if (!Files.exists(path)) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("error", "Fichier introuvable : " + path));
            }
            String content = Files.readString(path, StandardCharsets.UTF_8);
            return ResponseEntity.ok(Map.of("config", content, "path", path.toString()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", String.valueOf(e.getMessage())));
        }
    }

    /** Informations sur le fichier de configuration (pour l'affichage du statut). */
    @GetMapping("/status")
    public ResponseEntity<?> status() {
        Path path = Paths.get(configPath);
        try {
            Map<String, Object> info = new HashMap<>();
            info.put("file", path.toString());
            info.put("exists", Files.exists(path));
            if (Files.exists(path)) {
                info.put("lastModified", Files.getLastModifiedTime(path).toString());
                info.put("size", Files.size(path));
            }
            return ResponseEntity.ok(info);
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", String.valueOf(e.getMessage())));
        }
    }

    /**
     * Ecrit la nouvelle configuration, la valide et recharge HAProxy via WSL.
     * Si la validation ou le rechargement echoue, l'ancienne configuration est restauree.
     */
    @PostMapping("/config")
    public ResponseEntity<?> applyConfig(@RequestBody Map<String, String> body) {
        String content = body.get("config");
        if (content == null || content.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("ok", false, "message", "La configuration ne peut pas etre vide."));
        }

        Path path = Paths.get(configPath);
        Path backup = path.resolveSibling(path.getFileName().toString() + ".bak");
        try {
            if (path.getParent() != null) {
                Files.createDirectories(path.getParent());
            }
            if (Files.exists(path)) {
                Files.copy(path, backup, StandardCopyOption.REPLACE_EXISTING);
            }
            Files.writeString(path, content, StandardCharsets.UTF_8);

            String output = reloadViaWsl();
            boolean ok = output.contains("RELOAD_OK");
            if (!ok) {
                if (Files.exists(backup)) {
                    Files.copy(backup, path, StandardCopyOption.REPLACE_EXISTING);
                }
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                        .body(Map.of("ok", false, "message",
                                "Validation/rechargement echoue, ancienne configuration restauree.\n" + output));
            }
            return ResponseEntity.ok(Map.of("ok", true, "message", output.trim()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("ok", false, "message", "Erreur : " + String.valueOf(e.getMessage())));
        }
    }

    /** Lance le script WSL de validation/rechargement et retourne sa sortie. */
    private String reloadViaWsl() throws IOException, InterruptedException {
        ProcessBuilder pb = new ProcessBuilder("wsl", "-e", "bash", reloadScript);
        pb.redirectErrorStream(true);
        Process process = pb.start();
        String output;
        try (var in = process.getInputStream()) {
            output = new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
        if (!process.waitFor(30, TimeUnit.SECONDS)) {
            process.destroyForcibly();
            return output + "\nDelai depasse lors du rechargement HAProxy.";
        }
        return output;
    }
}
