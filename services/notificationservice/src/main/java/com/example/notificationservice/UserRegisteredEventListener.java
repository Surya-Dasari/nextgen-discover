package com.example.notificationservice;

import com.example.events.UserRegisteredEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.json.JsonMapper;

@Component
public class UserRegisteredEventListener {

    private static final Logger log =
            LoggerFactory.getLogger(UserRegisteredEventListener.class);

    private final JsonMapper jsonMapper;
    private final NotificationProcessingService processingService;

    public UserRegisteredEventListener(
            JsonMapper jsonMapper,
            NotificationProcessingService processingService) {
        this.jsonMapper = jsonMapper;
        this.processingService = processingService;
    }

    @KafkaListener(
            topics = "${app.kafka.topics.user-registered}",
            groupId = "${spring.kafka.consumer.group-id}"
    )
    public void consume(String payload) {

        try {
            UserRegisteredEvent event =
                    jsonMapper.readValue(payload, UserRegisteredEvent.class);

            processingService.process(event);

            log.info(
                    "Processed user registration event: eventId={}, userId={}",
                    event.eventId(),
                    event.userId()
            );

        } catch (JacksonException exception) {
            log.error("Unable to deserialize user registration event", exception);
            throw new IllegalArgumentException(
                    "Invalid user registration event payload",
                    exception
            );
        }
    }
}
