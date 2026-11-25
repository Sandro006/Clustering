package com.example.demo;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/messages")
public class MessageController {
    @Value("${CLUSTERING_DB_PASSWORD:}")
    private String password;

    private java.sql.Connection connect() throws SQLException {
        return DriverManager.getConnection("jdbc:mysql://127.0.0.1:3307/clustering?connectTimeout=3000", "clustering_app", password);
    }

    @GetMapping
    public ResponseEntity<?> list() {
        try (var connection = connect();
             var statement = connection.prepareStatement("SELECT id, content FROM messages ORDER BY id DESC LIMIT 50");
             var rows = statement.executeQuery()) {
            List<Map<String, Object>> messages = new ArrayList<>();
            while (rows.next()) messages.add(Map.of("id", rows.getLong("id"), "content", rows.getString("content")));
            return ResponseEntity.ok(messages);
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("error", "Impossible de lire les messages. Vérifie que MySQL est démarré."));
        }
    }

    @PostMapping
    public ResponseEntity<?> create(@RequestBody Map<String, String> body) {
        String content = body.get("content");
        if (content == null) content = "";
        content = content.strip();
        if (content.isEmpty() || content.length() > 500) {
            return ResponseEntity.badRequest().body(Map.of("error", "Le message doit contenir entre 1 et 500 caractères."));
        }
        try (var connection = connect();
             var statement = connection.prepareStatement("INSERT INTO messages (content) VALUES (?)")) {
            statement.setString(1, content);
            statement.executeUpdate();
            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("ok", true));
        } catch (SQLException e) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE).body(Map.of("error", "Impossible d'enregistrer le message. Vérifie que MySQL est démarré."));
        }
    }
}
