
package com.example.authservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestClientException;
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

        if (user == null
                || user.getEmail() == null
                || user.getEmail().isBlank()
                || user.getPassword() == null
                || user.getPassword().isBlank()) {

            return ResponseEntity
                    .badRequest()
                    .body("Email and password are required");
        }

        UserIdentity identity;

        try {
            identity = rest.postForObject(
                    userServiceUrl + "/users/authenticate",
                    user,
                    UserIdentity.class
            );

        } catch (HttpClientErrorException.Unauthorized ex) {

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Invalid credentials");

        } catch (HttpClientErrorException ex) {

            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body("User authentication request was rejected");

        } catch (HttpServerErrorException ex) {

            return ResponseEntity
                    .status(HttpStatus.BAD_GATEWAY)
                    .body("User Service encountered an error");

        } catch (RestClientException ex) {

            return ResponseEntity
                    .status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("User Service is unavailable");
        }

        if (identity == null
                || identity.userId() == null
                || identity.userId() <= 0
                || identity.email() == null
                || identity.email().isBlank()) {

            return ResponseEntity
                    .status(HttpStatus.BAD_GATEWAY)
                    .body("User Service returned an invalid identity");
        }

        String accessToken = jwtUtil.generateAccessToken(
                identity.email(),
                identity.userId()
        );

        String refreshToken = jwtUtil.generateRefreshToken(
                identity.email(),
                identity.userId()
        );

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

        String refreshToken = request.refreshToken();

        if (!jwtUtil.isRefreshTokenValid(refreshToken)) {

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Invalid or expired refresh token");
        }

        try {
            String email =
                    jwtUtil.getEmailFromRefreshToken(refreshToken);

            Long userId =
                    jwtUtil.getUserIdFromRefreshToken(refreshToken);

            String newAccessToken =
                    jwtUtil.generateAccessToken(email, userId);

            return ResponseEntity.ok(
                    new AccessTokenResponse(newAccessToken)
            );

        } catch (IllegalArgumentException ex) {

            return ResponseEntity
                    .status(HttpStatus.UNAUTHORIZED)
                    .body("Refresh token has an invalid identity");
        }
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

