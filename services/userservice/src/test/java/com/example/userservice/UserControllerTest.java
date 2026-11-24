
package com.example.userservice;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;

import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserControllerTest {

    @Mock
    private UserRepository repo;

    @Mock
    private UserRegistrationService registrationService;

    @Mock
    private PasswordEncoder passwordEncoder;

    private UserController controller;

    @BeforeEach
    void setUp() {
        controller = new UserController(
                repo,
                registrationService,
                passwordEncoder
        );
    }

    // ---------- SIGNUP TESTS ----------

    @Test
    void shouldCreateUserSuccessfully() {

        User user = new User();
        user.setName(" Surya ");
        user.setEmail(" SURYA@EXAMPLE.COM ");
        user.setPassword("password123");

        User savedUser = new User();
        savedUser.setName("Surya");
        savedUser.setEmail("surya@example.com");

        when(registrationService.register(
                "Surya",
                "surya@example.com",
                "password123"
        )).thenReturn(savedUser);

        ResponseEntity<String> response = controller.create(user);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertEquals("User created", response.getBody());

        verify(registrationService).register(
                "Surya",
                "surya@example.com",
                "password123"
        );

        verifyNoInteractions(repo, passwordEncoder);
    }

    @Test
    void shouldRejectSignupWhenRequiredFieldsAreMissing() {

        User user = new User();
        user.setEmail("surya@example.com");
        user.setPassword("password123");

        ResponseEntity<String> response = controller.create(user);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(
                "Name, email and password are required",
                response.getBody()
        );

        verifyNoInteractions(
                repo,
                registrationService,
                passwordEncoder
        );
    }

    @Test
    void shouldRejectDuplicateEmail() {

        User user = new User();
        user.setName("Surya");
        user.setEmail("surya@example.com");
        user.setPassword("password123");

        when(registrationService.register(
                "Surya",
                "surya@example.com",
                "password123"
        )).thenThrow(
                new IllegalArgumentException("Email already registered")
        );

        ResponseEntity<String> response = controller.create(user);

        assertEquals(HttpStatus.CONFLICT, response.getStatusCode());
        assertEquals("Email already registered", response.getBody());

        verify(registrationService).register(
                "Surya",
                "surya@example.com",
                "password123"
        );
    }

    @Test
    void shouldRejectNameLongerThan100Characters() {

        User user = new User();
        user.setName("A".repeat(101));
        user.setEmail("surya@example.com");
        user.setPassword("password123");

        ResponseEntity<String> response = controller.create(user);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertEquals(
                "Name must not exceed 100 characters",
                response.getBody()
        );

        verifyNoInteractions(
                repo,
                registrationService,
                passwordEncoder
        );
    }

    // ---------- LOGIN TESTS ----------

    @Test
    void shouldValidateCorrectCredentials() {

        User dbUser = new User();
        dbUser.setEmail("surya@example.com");
        dbUser.setPassword("encoded-password");

        User loginUser = new User();
        loginUser.setEmail(" SURYA@EXAMPLE.COM ");
        loginUser.setPassword("password123");

        when(repo.findByEmail("surya@example.com"))
                .thenReturn(Optional.of(dbUser));

        when(passwordEncoder.matches(
                "password123",
                "encoded-password"
        )).thenReturn(true);

        assertTrue(controller.validate(loginUser));

        verify(repo).findByEmail("surya@example.com");
        verify(passwordEncoder).matches(
                "password123",
                "encoded-password"
        );
    }

    @Test
    void shouldRejectIncorrectPassword() {

        User dbUser = new User();
        dbUser.setEmail("surya@example.com");
        dbUser.setPassword("encoded-password");

        User loginUser = new User();
        loginUser.setEmail("surya@example.com");
        loginUser.setPassword("wrong-password");

        when(repo.findByEmail("surya@example.com"))
                .thenReturn(Optional.of(dbUser));

        when(passwordEncoder.matches(
                "wrong-password",
                "encoded-password"
        )).thenReturn(false);

        assertFalse(controller.validate(loginUser));
    }

    @Test
    void shouldRejectUnknownEmail() {

        User loginUser = new User();
        loginUser.setEmail("unknown@example.com");
        loginUser.setPassword("password123");

        when(repo.findByEmail("unknown@example.com"))
                .thenReturn(Optional.empty());

        assertFalse(controller.validate(loginUser));

        verifyNoInteractions(passwordEncoder);
    }

    @Test
    void shouldRejectLoginWhenCredentialsAreMissing() {

        User loginUser = new User();
        loginUser.setEmail("surya@example.com");

        assertFalse(controller.validate(loginUser));

        verifyNoInteractions(repo, passwordEncoder);
    }
}

