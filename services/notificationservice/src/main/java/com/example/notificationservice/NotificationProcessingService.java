package com.example.notificationservice;

import com.example.events.UserRegisteredEvent;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class NotificationProcessingService {

    private final NotificationRecordRepository repository;

    public NotificationProcessingService(
            NotificationRecordRepository repository) {
        this.repository = repository;
    }

    @Transactional
    public void process(UserRegisteredEvent event) {

        if (event == null
                || event.eventId() == null
                || event.userId() == null
                || event.name() == null
                || event.email() == null
                || event.occurredAt() == null
                || !"USER_REGISTERED".equals(event.eventType())) {
            throw new IllegalArgumentException(
                    "Invalid USER_REGISTERED event"
            );
        }

        int inserted = repository.insertIfAbsent(
                event.eventId(),
                event.userId(),
                event.name(),
                event.email(),
                event.eventType(),
                event.occurredAt()
        );

        if (inserted == 1) {
            // A new notification request was persisted.
        }
    }
}
