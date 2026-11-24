
package com.example.userservice;

import com.example.events.UserRegisteredEvent;
import com.example.userservice.outbox.OutboxEvent;
import com.example.userservice.outbox.OutboxEventRepository;

import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Locale;
import java.util.UUID;

@Service
public class UserRegistrationService {

    private static final String EVENT_TYPE = "USER_REGISTERED";

    private final UserRepository userRepository;
    private final OutboxEventRepository outboxRepository;
    private final PasswordEncoder passwordEncoder;
    private final JsonMapper jsonMapper;

    public UserRegistrationService(
            UserRepository userRepository,
            OutboxEventRepository outboxRepository,
            PasswordEncoder passwordEncoder,
            JsonMapper jsonMapper) {

        this.userRepository = userRepository;
        this.outboxRepository = outboxRepository;
        this.passwordEncoder = passwordEncoder;
        this.jsonMapper = jsonMapper;
    }

    @Transactional
    public User register(String name, String email, String rawPassword) {

        String normalizedName = name.trim();
        String normalizedEmail =
                email.trim().toLowerCase(Locale.ROOT);

        if (userRepository.findByEmail(normalizedEmail).isPresent()) {
            throw new IllegalArgumentException(
                    "Email already registered"
            );
        }

        User user = new User();
        user.setName(normalizedName);
        user.setEmail(normalizedEmail);
        user.setPassword(passwordEncoder.encode(rawPassword));

        User savedUser = userRepository.save(user);

        UUID eventId = UUID.randomUUID();

        UserRegisteredEvent event = new UserRegisteredEvent(
                eventId,
                EVENT_TYPE,
                savedUser.getId(),
                savedUser.getName(),
                savedUser.getEmail(),
                Instant.now()
        );

        try {
            String payload = jsonMapper.writeValueAsString(event);

            OutboxEvent outboxEvent = new OutboxEvent(
                    eventId,
                    EVENT_TYPE,
                    payload
            );

            outboxRepository.save(outboxEvent);

        } catch (JacksonException exception) {
            throw new IllegalStateException(
                    "Failed to serialize user registration event",
                    exception
            );
        }

        return savedUser;
    }
}

