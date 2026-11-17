package com.example.catalogueservice;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class MovieService {

    private final MovieRepository repository;

    public MovieService(MovieRepository repository) {
        this.repository = repository;
    }

    public List<Movie> getAllMovies() {
        return repository.findAll();
    }

    public Optional<Movie> getMovieById(Long id) {
        return repository.findById(id);
    }

    public List<Movie> searchMovies(String title) {
        return repository.findByTitleContainingIgnoreCase(title);
    }

    public List<Movie> getMoviesByGenre(String genre) {
        return repository.findByGenreIgnoreCase(genre);
    }

    public Movie addMovie(Movie movie) {
        return repository.save(movie);
    }

    public void deleteMovie(Long id) {
        repository.deleteById(id);
    }
}
