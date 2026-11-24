
package com.example.notificationservice;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.UUID;

public interface NotificationRecordRepository
        extends JpaRepository<NotificationRecord, UUID> {

    // Persist Kafka events idempotently.
    @Modifying
    @Query(value = """
            INSERT INTO notification_records
                (event_id, user_id, name, email, event_type,
                 occurred_at, status)
            VALUES
                (:eventId, :userId, :name, :email, :eventType,
                 :occurredAt, 'PENDING')
            ON CONFLICT (event_id) DO NOTHING
            """, nativeQuery = true)
    int insertIfAbsent(
            @Param("eventId") UUID eventId,
            @Param("userId") Long userId,
            @Param("name") String name,
            @Param("email") String email,
            @Param("eventType") String eventType,
            @Param("occurredAt") Instant occurredAt
    );

    // Fetch notifications belonging to a specific user.
    Page<NotificationRecord> findByUserIdOrderByOccurredAtDesc(
            Long userId,
            Pageable pageable
    );

    // Count unread notifications for a specific user.
    long countByUserIdAndIsReadFalse(Long userId);

    // Mark a notification as read only for its owner.
    @Modifying
    @Query(value = """
            UPDATE notification_records
            SET is_read = TRUE
            WHERE event_id = :eventId
              AND user_id = :userId
              AND is_read = FALSE
            """, nativeQuery = true)
    int markAsRead(
            @Param("eventId") UUID eventId,
            @Param("userId") Long userId
    );
}

