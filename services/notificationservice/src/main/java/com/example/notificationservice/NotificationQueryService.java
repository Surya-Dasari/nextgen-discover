
package com.example.notificationservice;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class NotificationQueryService {

    private final NotificationRecordRepository repository;

    public NotificationQueryService(
            NotificationRecordRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public Page<NotificationRecord> getNotifications(
            Long userId,
            int page,
            int size) {

        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("Invalid user ID");
        }

        if (page < 0 || size < 1 || size > 100) {
            throw new IllegalArgumentException(
                    "Invalid pagination parameters"
            );
        }

        Pageable pageable = PageRequest.of(
                page,
                size,
                Sort.by(Sort.Direction.DESC, "occurredAt")
        );

        return repository.findByUserIdOrderByOccurredAtDesc(
                userId,
                pageable
        );
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(Long userId) {

        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("Invalid user ID");
        }

        return repository.countByUserIdAndIsReadFalse(userId);
    }

    @Transactional
    public boolean markAsRead(Long userId, UUID eventId) {

        if (userId == null || userId <= 0 || eventId == null) {
            throw new IllegalArgumentException(
                    "Invalid user ID or notification ID"
            );
        }

        // Repository parameter order: eventId, userId.
        return repository.markAsRead(eventId, userId) == 1;
    }
}

