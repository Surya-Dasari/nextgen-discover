package com.example.authservice;

public record UserIdentity(
        Long userId,
        String email
) {
}
