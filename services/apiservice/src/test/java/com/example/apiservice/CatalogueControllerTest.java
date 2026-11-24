package com.example.apiservice;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.*;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

import java.net.URI;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CatalogueControllerTest {

    @Mock
    private RestTemplate rest;

    @InjectMocks
    private CatalogueController controller;

    private final String baseUrl = "http://localhost:9004";

    @BeforeEach
    void setUp() {
        ReflectionTestUtils.setField(
                controller, "catalogueServiceUrl", baseUrl
        );
    }

    @Test
    void shouldGetAllMovies() {
        byte[] body = "[]".getBytes();

        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenReturn(ResponseEntity.ok(body));

        ResponseEntity<byte[]> response = controller.getAllMovies();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertArrayEquals(body, response.getBody());
    }

    @Test
    void shouldGetMovieById() {
        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenReturn(ResponseEntity.ok("movie".getBytes()));

        ResponseEntity<byte[]> response = controller.getMovieById(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertArrayEquals("movie".getBytes(), response.getBody());
    }

    @Test
    void shouldSearchMovies() {
        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenReturn(ResponseEntity.ok("[]".getBytes()));

        ResponseEntity<byte[]> response =
                controller.searchMovies("Inception");

        assertEquals(HttpStatus.OK, response.getStatusCode());
    }

    @Test
    void shouldGetMoviesByGenre() {
        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenReturn(ResponseEntity.ok("[]".getBytes()));

        ResponseEntity<byte[]> response =
                controller.getMoviesByGenre("Action");

        assertEquals(HttpStatus.OK, response.getStatusCode());
    }

    @Test
    void shouldAddMovie() {
        byte[] request = "{\"title\":\"Inception\"}".getBytes();

        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.POST),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenReturn(ResponseEntity.status(HttpStatus.CREATED)
                .body(request));

        ResponseEntity<byte[]> response = controller.addMovie(request);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
    }

    @Test
    void shouldDeleteMovie() {
        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.DELETE),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenReturn(ResponseEntity.noContent().build());

        ResponseEntity<byte[]> response = controller.deleteMovie(1L);

        assertEquals(HttpStatus.NO_CONTENT, response.getStatusCode());
    }

    @Test
    void shouldReturnServiceUnavailableWhenCatalogueIsDown() {
        when(rest.exchange(
                any(URI.class),
                eq(HttpMethod.GET),
                any(HttpEntity.class),
                eq(byte[].class)
        )).thenThrow(new ResourceAccessException("Connection refused"));

        ResponseEntity<byte[]> response = controller.getAllMovies();

        assertEquals(
                HttpStatus.SERVICE_UNAVAILABLE,
                response.getStatusCode()
        );
    }
}
