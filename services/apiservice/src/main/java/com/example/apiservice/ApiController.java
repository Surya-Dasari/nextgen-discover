
package com.example.apiservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;

@RestController
public class ApiController {

    private final RestTemplate rest = new RestTemplate();

    @Value("${auth.url}")
    private String authServiceUrl;

    @Value("${user.url}")
    private String userServiceUrl;

    // ---------- SIGNUP ----------

    @PostMapping("/signup")
    public ResponseEntity<String> signup(@RequestBody User user) {

        try {
            String response = rest.postForObject(
                    userServiceUrl + "/users",
                    user,
                    String.class
            );

            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(response);

        } catch (HttpClientErrorException ex) {

            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());

        } catch (HttpServerErrorException ex) {

            return ResponseEntity
                    .status(HttpStatus.BAD_GATEWAY)
                    .body("User service error");

        } catch (Exception ex) {
            ex.printStackTrace();

            return ResponseEntity
                    .status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("User service unavailable");
        }
    }

    // ---------- LOGIN ----------

    @PostMapping("/login")
    public ResponseEntity<String> login(@RequestBody User user) {

        try {
            String response = rest.postForObject(
                    authServiceUrl + "/login",
                    user,
                    String.class
            );

            return ResponseEntity.ok(response);

        } catch (HttpClientErrorException ex) {

            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body("Invalid credentials");

        } catch (HttpServerErrorException ex) {

            return ResponseEntity
                    .status(HttpStatus.BAD_GATEWAY)
                    .body("Authentication service error");

        } catch (Exception ex) {
            ex.printStackTrace();

            return ResponseEntity
                    .status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Authentication service unavailable");
        }
    }

    // ---------- REFRESH ACCESS TOKEN ----------

    @PostMapping("/refresh")
    public ResponseEntity<String> refresh(
            @RequestBody RefreshRequest request) {

        try {
            String response = rest.postForObject(
                    authServiceUrl + "/refresh",
                    request,
                    String.class
            );

            return ResponseEntity.ok(response);

        } catch (HttpClientErrorException ex) {

            return ResponseEntity
                    .status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());

        } catch (HttpServerErrorException ex) {

            return ResponseEntity
                    .status(HttpStatus.BAD_GATEWAY)
                    .body("Authentication service error");

        } catch (Exception ex) {
            ex.printStackTrace();

            return ResponseEntity
                    .status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Authentication service unavailable");
        }
    }

    // ---------- PROTECTED PROFILE ----------

    @GetMapping("/profile")
    public ResponseEntity<String> profile() {

        return ResponseEntity.ok(
                "Welcome! You have accessed the protected profile endpoint."
        );
    }

    // ---------- REQUEST DTO ----------

    public record RefreshRequest(String refreshToken) {}
}

