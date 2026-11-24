package com.example.notificationservice;

import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final NotificationQueryService queryService;

    public NotificationController(NotificationQueryService queryService) {
        this.queryService = queryService;
    }

    @GetMapping
    public Page<NotificationRecord> getNotifications(
            @RequestHeader("X-Authenticated-User-Id") String userId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        return queryService.getNotifications(
                parseUserId(userId), page, size);
    }

    @GetMapping("/unread-count")
    public Map<String, Long> getUnreadCount(
            @RequestHeader("X-Authenticated-User-Id") String userId) {

        long count = queryService.getUnreadCount(parseUserId(userId));

        return Map.of("unreadCount", count);
    }

    @PatchMapping("/{eventId}/read")
    public ResponseEntity<Void> markAsRead(
            @RequestHeader("X-Authenticated-User-Id") String userId,
            @PathVariable UUID eventId) {

        boolean updated = queryService.markAsRead(
                parseUserId(userId), eventId);

        if (!updated) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.noContent().build();
    }

    private Long parseUserId(String userId) {
        try {
            long id = Long.parseLong(userId);

            if (id <= 0) {
                throw new NumberFormatException();
            }

            return id;

        } catch (NumberFormatException exception) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Invalid authenticated user identity");
        }
    }
}
