package com.example.apiservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.util.UUID;

@RestController
public class ApiController {

    private final RestTemplate rest;

    public ApiController(RestTemplate rest) {
        this.rest = rest;
    }

    @Value("${auth.url}")
    private String authServiceUrl;

    @Value("${user.url}")
    private String userServiceUrl;

    @Value("${notification.url}")
    private String notificationServiceUrl;

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
            return ResponseEntity.status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());

        } catch (HttpServerErrorException ex) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("User service error");

        } catch (ResourceAccessException ex) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
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
            return ResponseEntity.status(ex.getStatusCode())
                    .body("Invalid credentials");

        } catch (HttpServerErrorException ex) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("Authentication service error");

        } catch (ResourceAccessException ex) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Authentication service unavailable");
        }
    }

    // ---------- REFRESH TOKEN ----------

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
            return ResponseEntity.status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());

        } catch (HttpServerErrorException ex) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY)
                    .body("Authentication service error");

        } catch (ResourceAccessException ex) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
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

    // ---------- GET USER NOTIFICATIONS ----------

    @GetMapping("/notifications")
    public ResponseEntity<String> getNotifications(
            @RequestHeader("X-Authenticated-User-Id") String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        if (!isValidUserId(userId) || page < 0 || size < 1 || size > 100) {
            return ResponseEntity.badRequest()
                    .body("Invalid request parameters");
        }

        String url = notificationServiceUrl
                + "/notifications?page=" + page
                + "&size=" + size;

        return forwardNotificationRequest(
                url, HttpMethod.GET, userId
        );
    }

    // ---------- GET UNREAD COUNT ----------

    @GetMapping("/notifications/unread-count")
    public ResponseEntity<String> getUnreadCount(
            @RequestHeader("X-Authenticated-User-Id") String userId) {

        if (!isValidUserId(userId)) {
            return ResponseEntity.badRequest()
                    .body("Invalid authenticated user identity");
        }

        String url = notificationServiceUrl
                + "/notifications/unread-count";

        return forwardNotificationRequest(
                url, HttpMethod.GET, userId
        );
    }

    // ---------- MARK NOTIFICATION AS READ ----------

    @PatchMapping("/notifications/{eventId}/read")
    public ResponseEntity<String> markAsRead(
            @RequestHeader("X-Authenticated-User-Id") String userId,
            @PathVariable UUID eventId) {

        if (!isValidUserId(userId)) {
            return ResponseEntity.badRequest()
                    .body("Invalid authenticated user identity");
        }

        String url = notificationServiceUrl
                + "/notifications/" + eventId + "/read";

        return forwardNotificationRequest(
                url, HttpMethod.PATCH, userId
        );
    }

    // ---------- NOTIFICATION SERVICE FORWARDING ----------

    private ResponseEntity<String> forwardNotificationRequest(
            String url,
            HttpMethod method,
            String userId) {

        HttpHeaders headers = new HttpHeaders();

        headers.set("X-Authenticated-User-Id", userId);

        HttpEntity<Void> request = new HttpEntity<>(headers);

        try {
            return rest.exchange(
                    url,
                    method,
                    request,
                    String.class
            );

        } catch (HttpStatusCodeException ex) {
            return ResponseEntity.status(ex.getStatusCode())
                    .body(ex.getResponseBodyAsString());

        } catch (ResourceAccessException ex) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body("Notification service unavailable");
        }
    }

    // ---------- USER ID VALIDATION ----------

    private boolean isValidUserId(String userId) {
        try {
            return userId != null && Long.parseLong(userId) > 0;
        } catch (NumberFormatException ex) {
            return false;
        }
    }

    // ---------- REQUEST DTO ----------

    public record RefreshRequest(String refreshToken) {}
}
