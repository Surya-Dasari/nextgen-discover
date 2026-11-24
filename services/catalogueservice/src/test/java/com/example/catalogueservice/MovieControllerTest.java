
package com.example.catalogueservice;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

@ExtendWith(MockitoExtension.class)
class MovieControllerTest {

    @Mock
    private MovieService movieService;

    @InjectMocks
    private MovieController movieController;

    private Movie movie;

    @BeforeEach
    void setUp() {
        movie = new Movie();
        movie.setTitle("Inception");
        movie.setDescription("A science fiction movie");
        movie.setGenre("Sci-Fi");
        movie.setReleaseYear(2010);
        movie.setRating(8.8);
        movie.setPosterUrl("https://example.com/inception.jpg");
    }

    @Test
    void getAllMoviesShouldReturnMovies() {
        when(movieService.getAllMovies()).thenReturn(List.of(movie));

        List<Movie> result = movieController.getAllMovies();

        assertEquals(1, result.size());
        assertEquals("Inception", result.get(0).getTitle());
        verify(movieService).getAllMovies();
    }

    @Test
    void getAllMoviesShouldReturnEmptyList() {
        when(movieService.getAllMovies()).thenReturn(List.of());

        List<Movie> result = movieController.getAllMovies();

        assertTrue(result.isEmpty());
        verify(movieService).getAllMovies();
    }

    @Test
    void getMovieByIdShouldReturnMovieWhenFound() {
        when(movieService.getMovieById(1L))
            .thenReturn(Optional.of(movie));

        ResponseEntity<Movie> response =
            movieController.getMovieById(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("Inception", response.getBody().getTitle());
        verify(movieService).getMovieById(1L);
    }

    @Test
    void getMovieByIdShouldReturn404WhenNotFound() {
        when(movieService.getMovieById(99L))
            .thenReturn(Optional.empty());

        ResponseEntity<Movie> response =
            movieController.getMovieById(99L);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        assertNull(response.getBody());
        verify(movieService).getMovieById(99L);
    }

    @Test
    void searchMoviesShouldReturnMatchingMovies() {
        when(movieService.searchMovies("Inception"))
            .thenReturn(List.of(movie));

        List<Movie> result =
            movieController.searchMovies("Inception");

        assertEquals(1, result.size());
        assertEquals("Inception", result.get(0).getTitle());
        verify(movieService).searchMovies("Inception");
    }

    @Test
    void getMoviesByGenreShouldReturnMatchingMovies() {
        when(movieService.getMoviesByGenre("Sci-Fi"))
            .thenReturn(List.of(movie));

        List<Movie> result =
            movieController.getMoviesByGenre("Sci-Fi");

        assertEquals(1, result.size());
        assertEquals("Sci-Fi", result.get(0).getGenre());
        verify(movieService).getMoviesByGenre("Sci-Fi");
    }

    @Test
    void addMovieShouldReturn201Created() {
        when(movieService.addMovie(movie)).thenReturn(movie);

        ResponseEntity<Movie> response =
            movieController.addMovie(movie);

        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("Inception", response.getBody().getTitle());
        verify(movieService).addMovie(movie);
    }

    @Test
    void deleteMovieShouldReturn204WhenMovieExists() {
        when(movieService.getMovieById(1L))
            .thenReturn(Optional.of(movie));

        ResponseEntity<Void> response =
            movieController.deleteMovie(1L);

        assertEquals(HttpStatus.NO_CONTENT, response.getStatusCode());
        verify(movieService).getMovieById(1L);
        verify(movieService).deleteMovie(1L);
    }

    @Test
    void deleteMovieShouldReturn404WhenMovieDoesNotExist() {
        when(movieService.getMovieById(99L))
            .thenReturn(Optional.empty());

        ResponseEntity<Void> response =
            movieController.deleteMovie(99L);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        verify(movieService).getMovieById(99L);
        verify(movieService, never()).deleteMovie(99L);
    }
}

