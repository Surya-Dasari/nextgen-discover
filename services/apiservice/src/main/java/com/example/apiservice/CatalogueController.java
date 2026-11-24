package com.example.apiservice;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;

@RestController
public class CatalogueController {

    private final RestTemplate rest;
    private final String catalogueServiceUrl;

    public CatalogueController(
            RestTemplate rest,
            @Value("${catalogue.url}") String catalogueServiceUrl) {
        this.rest = rest;
        this.catalogueServiceUrl = catalogueServiceUrl;
    }

    @GetMapping("/movies")
    public ResponseEntity<byte[]> getAllMovies() {
        return forward(HttpMethod.GET, "/movies", null);
    }

    @GetMapping("/movies/{id}")
    public ResponseEntity<byte[]> getMovieById(@PathVariable Long id) {
        return forward(HttpMethod.GET, "/movies/" + id, null);
    }

    @GetMapping("/movies/search")
    public ResponseEntity<byte[]> searchMovies(@RequestParam String title) {
        URI uri = UriComponentsBuilder
                .fromUriString(catalogueServiceUrl)
                .path("/movies/search")
                .queryParam("title", title)
                .build()
                .encode()
                .toUri();

        return forward(uri, HttpMethod.GET, null);
    }

    @GetMapping("/movies/genre/{genre}")
    public ResponseEntity<byte[]> getMoviesByGenre(
            @PathVariable String genre) {
        return forward(
                HttpMethod.GET,
                "/movies/genre/" + genre,
                null
        );
    }

    @PostMapping("/movies")
    public ResponseEntity<byte[]> addMovie(@RequestBody byte[] movie) {
        return forward(HttpMethod.POST, "/movies", movie);
    }

    @DeleteMapping("/movies/{id}")
    public ResponseEntity<byte[]> deleteMovie(@PathVariable Long id) {
        return forward(HttpMethod.DELETE, "/movies/" + id, null);
    }

    private ResponseEntity<byte[]> forward(
            HttpMethod method, String path, byte[] body) {
        URI uri = UriComponentsBuilder
                .fromUriString(catalogueServiceUrl)
                .path(path)
                .build()
                .encode()
                .toUri();

        return forward(uri, method, body);
    }

    private ResponseEntity<byte[]> forward(
            URI uri, HttpMethod method, byte[] body) {

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            ResponseEntity<byte[]> response = rest.exchange(
                    uri,
                    method,
                    new HttpEntity<>(body, headers),
                    byte[].class
            );

            return relay(response.getStatusCode(), response.getHeaders(),
                    response.getBody());

        } catch (RestClientResponseException ex) {
            return relay(ex.getStatusCode(), ex.getResponseHeaders(),
                    ex.getResponseBodyAsByteArray());

        } catch (ResourceAccessException ex) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .contentType(MediaType.TEXT_PLAIN)
                    .body("Catalogue service unavailable"
                            .getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }
    }

    private ResponseEntity<byte[]> relay(
            HttpStatusCode status,
            HttpHeaders sourceHeaders,
            byte[] body) {

        ResponseEntity.BodyBuilder response =
                ResponseEntity.status(status);

        if (sourceHeaders != null
                && sourceHeaders.getContentType() != null) {
            response.contentType(sourceHeaders.getContentType());
        }

        return response.body(body);
    }
}
