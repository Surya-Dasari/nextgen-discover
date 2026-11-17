
package com.example.authservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

@RestController
public class AuthController {

    @Value("${userservice.url}")
    private String userServiceUrl;

    private final RestTemplate rest = new RestTemplate();

    private final JwtUtil jwtUtil;

    public AuthController(JwtUtil jwtUtil) {
        this.jwtUtil = jwtUtil;
    }

    // ---------- LOGIN ----------

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User user) {

        Boolean valid = rest.postForObject(
                userServiceUrl + "/users/validate",
                user,
                Boolean.class
        );

        if (!Boolean.TRUE.equals(valid)) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Invalid credentials");
        }

        String accessToken =
                jwtUtil.generateAccessToken(user.getEmail());

        String refreshToken =
                jwtUtil.generateRefreshToken(user.getEmail());

        return ResponseEntity.ok(
                new TokenResponse(accessToken, refreshToken)
        );
    }

    // ---------- REFRESH ACCESS TOKEN ----------

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(
            @RequestBody RefreshRequest request) {

        if (request == null
                || request.refreshToken() == null
                || request.refreshToken().isBlank()) {

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Refresh token is required");
        }

        if (!jwtUtil.isRefreshTokenValid(request.refreshToken())) {
            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Invalid or expired refresh token");
        }

        String email =
                jwtUtil.getEmailFromRefreshToken(request.refreshToken());

        String newAccessToken =
                jwtUtil.generateAccessToken(email);

        return ResponseEntity.ok(
                new AccessTokenResponse(newAccessToken)
        );
    }

    // ---------- RESPONSE DTOs ----------

    public record TokenResponse(
            String accessToken,
            String refreshToken
    ) {}

    public record AccessTokenResponse(
            String accessToken
    ) {}

    public record RefreshRequest(
            String refreshToken
    ) {}
}

