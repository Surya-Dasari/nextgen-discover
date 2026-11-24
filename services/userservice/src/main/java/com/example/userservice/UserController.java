
package com.example.userservice;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Locale;
import java.util.Optional;

@RestController
public class UserController {

    private final UserRepository repo;
    private final UserRegistrationService registrationService;
    private final PasswordEncoder passwordEncoder;

    public UserController(
            UserRepository repo,
            UserRegistrationService registrationService,
            PasswordEncoder passwordEncoder) {

        this.repo = repo;
        this.registrationService = registrationService;
        this.passwordEncoder = passwordEncoder;
    }

    // ---------- SIGNUP ----------

    @PostMapping("/users")
    public ResponseEntity<String> create(@RequestBody User user) {

        if (user.getName() == null || user.getName().isBlank()
                || user.getEmail() == null || user.getEmail().isBlank()
                || user.getPassword() == null
                || user.getPassword().isBlank()) {

            return ResponseEntity.badRequest()
                    .body("Name, email and password are required");
        }

        String name = user.getName().trim();
        String email = user.getEmail().trim().toLowerCase(Locale.ROOT);

        if (name.length() > 100) {
            return ResponseEntity.badRequest()
                    .body("Name must not exceed 100 characters");
        }

        try {
            registrationService.register(
                    name,
                    email,
                    user.getPassword()
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body("User created");

        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Email already registered");
        }
    }

    // ---------- LOGIN VALIDATION (EXISTING) ----------

    @PostMapping("/users/validate")
    public boolean validate(@RequestBody User user) {

        if (user.getEmail() == null || user.getEmail().isBlank()
                || user.getPassword() == null
                || user.getPassword().isBlank()) {
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

    // ---------- AUTHENTICATE AND RETURN USER ID ----------

    @PostMapping("/users/authenticate")
    public ResponseEntity<IdentityResponse> authenticate(
            @RequestBody User user) {

        if (user == null
                || user.getEmail() == null
                || user.getEmail().isBlank()
                || user.getPassword() == null
                || user.getPassword().isBlank()) {

            return ResponseEntity.badRequest().build();
        }

        String email = user.getEmail()
                .trim()
                .toLowerCase(Locale.ROOT);

        Optional<User> dbUser = repo.findByEmail(email);

        if (dbUser.isEmpty()
                || !passwordEncoder.matches(
                        user.getPassword(),
                        dbUser.get().getPassword())) {

            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .build();
        }

        User authenticatedUser = dbUser.get();

        return ResponseEntity.ok(
                new IdentityResponse(
                        authenticatedUser.getId(),
                        authenticatedUser.getEmail()
                )
        );
    }

    // ---------- RESPONSE DTO ----------

    public record IdentityResponse(
            Long userId,
            String email
    ) {}
}

