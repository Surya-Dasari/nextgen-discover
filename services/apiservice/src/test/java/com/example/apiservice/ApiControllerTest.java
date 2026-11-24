
package com.example.apiservice;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class ApiControllerTest {

    @Mock
    private RestTemplate rest;

    @InjectMocks
    private ApiController controller;

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(
                controller, "authServiceUrl", "http://localhost:9001"
        );
        ReflectionTestUtils.setField(
                controller, "userServiceUrl", "http://localhost:9002"
        );
    }

    // ---------- SIGNUP TESTS ----------

    @Test
    void shouldSignupSuccessfully() {

        User user = new User();
        when(rest.postForObject(
                eq("http://localhost:9002/users"),
                eq(user),
                eq(String.class)
        )).thenReturn("User created");

        ResponseEntity<String> response = controller.signup(user);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertEquals("User created", response.getBody());
    }

    @Test
    void shouldReturnClientErrorDuringSignup() {

        User user = new User();

        when(rest.postForObject(anyString(), eq(user), eq(String.class)))
                .thenThrow(HttpClientErrorException.create(
                        HttpStatus.CONFLICT,
                        "Conflict",
                        HttpHeaders.EMPTY,
                        "Email already registered".getBytes(),
                        null
                ));

        ResponseEntity<String> response = controller.signup(user);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertEquals("Email already registered", response.getBody());
    }

    @Test
    void shouldReturnBadGatewayDuringSignupOnServerError() {

        User user = new User();

        when(rest.postForObject(anyString(), eq(user), eq(String.class)))
                .thenThrow(new HttpServerErrorException(
                        HttpStatus.INTERNAL_SERVER_ERROR
                ));

        ResponseEntity<String> response = controller.signup(user);

        assertEquals(HttpStatus.BAD_GATEWAY, response.getStatusCode());
        assertEquals("User service error", response.getBody());
    }

    // ---------- LOGIN TESTS ----------

    @Test
    void shouldLoginSuccessfully() {

        User user = new User();

        when(rest.postForObject(
                eq("http://localhost:9001/login"),
                eq(user),
                eq(String.class)
        )).thenReturn("JWT_TOKEN");

        ResponseEntity<String> response = controller.login(user);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("JWT_TOKEN", response.getBody());
    }

    @Test
    void shouldRejectInvalidLoginCredentials() {

        User user = new User();

        when(rest.postForObject(anyString(), eq(user), eq(String.class)))
                .thenThrow(new HttpClientErrorException(
                        HttpStatus.UNAUTHORIZED
                ));

        ResponseEntity<String> response = controller.login(user);

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
        assertEquals("Invalid credentials", response.getBody());
    }

    @Test
    void shouldReturnBadGatewayDuringLoginOnServerError() {

        User user = new User();

        when(rest.postForObject(anyString(), eq(user), eq(String.class)))
                .thenThrow(new HttpServerErrorException(
                        HttpStatus.INTERNAL_SERVER_ERROR
                ));

        ResponseEntity<String> response = controller.login(user);

        assertEquals(HttpStatus.BAD_GATEWAY, response.getStatusCode());
        assertEquals("Authentication service error", response.getBody());
    }

    // ---------- REFRESH TOKEN TESTS ----------

    @Test
    void shouldRefreshTokenSuccessfully() {

        ApiController.RefreshRequest request =
                new ApiController.RefreshRequest("refresh-token");

        when(rest.postForObject(
                eq("http://localhost:9001/refresh"),
                eq(request),
                eq(String.class)
        )).thenReturn("NEW_ACCESS_TOKEN");

        ResponseEntity<String> response = controller.refresh(request);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("NEW_ACCESS_TOKEN", response.getBody());
    }

    @Test
    void shouldReturnClientErrorDuringTokenRefresh() {

        ApiController.RefreshRequest request =
                new ApiController.RefreshRequest("invalid-token");

        when(rest.postForObject(anyString(), eq(request), eq(String.class)))
                .thenThrow(HttpClientErrorException.create(
                        HttpStatus.UNAUTHORIZED,
                        "Unauthorized",
                        HttpHeaders.EMPTY,
                        "Invalid refresh token".getBytes(),
                        null
                ));

        ResponseEntity<String> response = controller.refresh(request);

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
        assertEquals("Invalid refresh token", response.getBody());
    }

    @Test
    void shouldReturnBadGatewayDuringTokenRefreshOnServerError() {

        ApiController.RefreshRequest request =
                new ApiController.RefreshRequest("refresh-token");

        when(rest.postForObject(anyString(), eq(request), eq(String.class)))
                .thenThrow(new HttpServerErrorException(
                        HttpStatus.INTERNAL_SERVER_ERROR
                ));

        ResponseEntity<String> response = controller.refresh(request);

        assertEquals(HttpStatus.BAD_GATEWAY, response.getStatusCode());
        assertEquals("Authentication service error", response.getBody());
    }

    // ---------- PROFILE TEST ----------

    @Test
    void shouldReturnProfileSuccessfully() {

        ResponseEntity<String> response = controller.profile();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals(
                "Welcome! You have accessed the protected profile endpoint.",
                response.getBody()
        );
    }

    // ---------- USER DTO TEST ----------

    @Test
    void shouldSetAndGetUserFields() {

        User user = new User();

        user.setName("Surya");
        user.setEmail("surya@example.com");
        user.setPassword("password123");

        assertEquals("Surya", user.getName());
        assertEquals("surya@example.com", user.getEmail());
        assertEquals("password123", user.getPassword());
    }
}
