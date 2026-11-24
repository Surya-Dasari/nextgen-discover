
package com.example.notificationservice;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "notification_records")
public class NotificationRecord {

    @Id
    @Column(nullable = false, updatable = false)
    private UUID eventId;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 255)
    private String email;

    @Column(nullable = false, length = 100)
    private String eventType;

    @Column(nullable = false)
    private Instant occurredAt;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NotificationStatus status;

    @Column(name = "is_read", nullable = false)
    private boolean isRead = false;

    protected NotificationRecord() {
    }

    public NotificationRecord(
            UUID eventId,
            Long userId,
            String name,
            String email,
            String eventType,
            Instant occurredAt) {

        this.eventId = eventId;
        this.userId = userId;
        this.name = name;
        this.email = email;
        this.eventType = eventType;
        this.occurredAt = occurredAt;
        this.status = NotificationStatus.PENDING;
        this.isRead = false;
    }

    public UUID getEventId() {
        return eventId;
    }

    public Long getUserId() {
        return userId;
    }

    public String getName() {
        return name;
    }

    public String getEmail() {
        return email;
    }

    public String getEventType() {
        return eventType;
    }

    public Instant getOccurredAt() {
        return occurredAt;
    }

    public NotificationStatus getStatus() {
        return status;
    }

    public boolean isRead() {
        return isRead;
    }
}

