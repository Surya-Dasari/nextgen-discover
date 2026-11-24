
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

@ExtendWith(MockitoExtension.class)
class MovieServiceTest {

    @Mock
    private MovieRepository repository;

    @InjectMocks
    private MovieService movieService;

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
    void getAllMoviesShouldReturnAllMovies() {
        when(repository.findAll()).thenReturn(List.of(movie));

        List<Movie> result = movieService.getAllMovies();

        assertEquals(1, result.size());
        assertEquals("Inception", result.get(0).getTitle());
        verify(repository).findAll();
    }

    @Test
    void getAllMoviesShouldReturnEmptyList() {
        when(repository.findAll()).thenReturn(List.of());

        List<Movie> result = movieService.getAllMovies();

        assertTrue(result.isEmpty());
        verify(repository).findAll();
    }

    @Test
    void getMovieByIdShouldReturnMovieWhenFound() {
        when(repository.findById(1L)).thenReturn(Optional.of(movie));

        Optional<Movie> result = movieService.getMovieById(1L);

        assertTrue(result.isPresent());
        assertEquals("Inception", result.get().getTitle());
        verify(repository).findById(1L);
    }

    @Test
    void getMovieByIdShouldReturnEmptyWhenNotFound() {
        when(repository.findById(99L)).thenReturn(Optional.empty());

        Optional<Movie> result = movieService.getMovieById(99L);

        assertTrue(result.isEmpty());
        verify(repository).findById(99L);
    }

    @Test
    void searchMoviesShouldReturnMatchingMovies() {
        when(repository.findByTitleContainingIgnoreCase("incep"))
            .thenReturn(List.of(movie));

        List<Movie> result = movieService.searchMovies("incep");

        assertEquals(1, result.size());
        assertEquals("Inception", result.get(0).getTitle());
        verify(repository).findByTitleContainingIgnoreCase("incep");
    }

    @Test
    void getMoviesByGenreShouldReturnMatchingMovies() {
        when(repository.findByGenreIgnoreCase("Sci-Fi"))
            .thenReturn(List.of(movie));

        List<Movie> result = movieService.getMoviesByGenre("Sci-Fi");

        assertEquals(1, result.size());
        assertEquals("Sci-Fi", result.get(0).getGenre());
        verify(repository).findByGenreIgnoreCase("Sci-Fi");
    }

    @Test
    void addMovieShouldSaveAndReturnMovie() {
        when(repository.save(movie)).thenReturn(movie);

        Movie result = movieService.addMovie(movie);

        assertNotNull(result);
        assertEquals("Inception", result.getTitle());
        verify(repository).save(movie);
    }

    @Test
    void deleteMovieShouldCallRepository() {
        movieService.deleteMovie(1L);

        verify(repository).deleteById(1L);
    }
}
