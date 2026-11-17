
package com.example.userservice;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Locale;
import java.util.Optional;

@RestController
public class UserController {

    private final UserRepository repo;
    private final PasswordEncoder passwordEncoder =
            new BCryptPasswordEncoder();

    public UserController(UserRepository repo) {
        this.repo = repo;
    }

    // ---------- SIGNUP ----------
    @PostMapping("/users")
    public ResponseEntity<String> create(@RequestBody User user) {

        if (user.getEmail() == null || user.getEmail().isBlank()
                || user.getPassword() == null || user.getPassword().isBlank()) {
            return ResponseEntity.badRequest()
                    .body("Email and password are required");
        }

        String email = user.getEmail().trim().toLowerCase(Locale.ROOT);
        user.setEmail(email);

        if (repo.findByEmail(email).isPresent()) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Email already registered");
        }

        user.setPassword(passwordEncoder.encode(user.getPassword()));
        repo.save(user);

        return ResponseEntity.status(HttpStatus.CREATED)
                .body("User created");
    }

    // ---------- LOGIN VALIDATION ----------
    @PostMapping("/users/validate")
    public boolean validate(@RequestBody User user) {

        if (user.getEmail() == null || user.getEmail().isBlank()
                || user.getPassword() == null || user.getPassword().isBlank()) {
            return false;
        }

        String email = user.getEmail().trim().toLowerCase(Locale.ROOT);

        Optional<User> dbUser = repo.findByEmail(email);

        if (dbUser.isEmpty()) {
            return false;
        }

        return passwordEncoder.matches(
                user.getPassword(),
                dbUser.get().getPassword()
        );
    }
}

