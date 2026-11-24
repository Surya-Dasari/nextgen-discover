package com.example.userservice.outbox;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

@Component
@ConditionalOnProperty(
        prefix = "app.outbox.publisher",
        name = "enabled",
        havingValue = "true"
)
public class OutboxPublisher {

    private static final Logger log =
            LoggerFactory.getLogger(OutboxPublisher.class);

    private final OutboxEventRepository outboxRepository;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final String topic;

    public OutboxPublisher(
            OutboxEventRepository outboxRepository,
            KafkaTemplate<String, String> kafkaTemplate,
            org.springframework.core.env.Environment environment) {

        this.outboxRepository = outboxRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.topic = environment.getProperty(
                "app.kafka.topics.user-registered",
                "user.registered"
        );
    }

    @Scheduled(
            fixedDelayString =
                    "${app.outbox.publisher.poll-interval-ms:5000}"
    )
    @Transactional
    public void publishPendingEvents() {

        List<OutboxEvent> events =
                outboxRepository.findTop100ByStatusOrderByCreatedAtAsc(
                        "PENDING"
                );

        for (OutboxEvent event : events) {
            try {
                kafkaTemplate.send(
                        topic,
                        event.getId().toString(),
                        event.getPayload()
                ).get(10, TimeUnit.SECONDS);

                event.markPublished();

                log.info(
                        "Published outbox event: eventId={}, eventType={}",
                        event.getId(),
                        event.getEventType()
                );

            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();

                log.warn(
                        "Kafka publishing interrupted for event {}",
                        event.getId()
                );

                break;

            } catch (ExecutionException | TimeoutException exception) {
                log.error(
                        "Kafka publishing failed for event {}. It will be retried.",
                        event.getId(),
                        exception
                );
            }
        }
    }
}
