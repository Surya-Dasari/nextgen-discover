package com.example.events;

import java.time.Instant;
import java.util.UUID;

public record UserRegisteredEvent(
        UUID eventId,
        String eventType,
        Long userId,
        String name,
        String email,
        Instant occurredAt
) {
}
