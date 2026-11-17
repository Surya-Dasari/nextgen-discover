
package com.example.authservice;

import io.jsonwebtoken.io.Encoders;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class JwtUtilTest {

    private static final String TEST_SECRET =
            Encoders.BASE64.encode(new byte[32]);

    @Test
    void shouldGenerateAccessToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String token = jwtUtil.generateAccessToken("testuser");

        assertNotNull(token);
        assertEquals(3, token.split("\\.").length);
        assertTrue(jwtUtil.isAccessTokenValid(token));
    }

    @Test
    void shouldGenerateRefreshToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String token = jwtUtil.generateRefreshToken("testuser");

        assertNotNull(token);
        assertTrue(jwtUtil.isRefreshTokenValid(token));
    }

    @Test
    void shouldRejectRefreshTokenAsAccessToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String refreshToken = jwtUtil.generateRefreshToken("testuser");

        assertFalse(jwtUtil.isAccessTokenValid(refreshToken));
    }

    @Test
    void shouldRejectAccessTokenAsRefreshToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String accessToken = jwtUtil.generateAccessToken("testuser");

        assertFalse(jwtUtil.isRefreshTokenValid(accessToken));
    }

    @Test
    void shouldExtractEmailFromRefreshToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String refreshToken = jwtUtil.generateRefreshToken("testuser");

        assertEquals("testuser",
                jwtUtil.getEmailFromRefreshToken(refreshToken));
    }

    @Test
    void shouldAcceptValidAccessToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String token = jwtUtil.generateToken("testuser");

        assertTrue(jwtUtil.isTokenValid(token));
    }

    @Test
    void shouldRejectExpiredAccessToken() throws InterruptedException {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 1, 604800000);

        String token = jwtUtil.generateAccessToken("testuser");

        Thread.sleep(20);

        assertFalse(jwtUtil.isAccessTokenValid(token));
    }

    @Test
    void shouldRejectExpiredRefreshToken() throws InterruptedException {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 1);

        String token = jwtUtil.generateRefreshToken("testuser");

        Thread.sleep(20);

        assertFalse(jwtUtil.isRefreshTokenValid(token));
    }

    @Test
    void shouldRejectTamperedToken() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        String token = jwtUtil.generateAccessToken("testuser");
        String[] parts = token.split("\\.");

        String signature = parts[2];

        String modifiedSignature =
                (signature.charAt(0) == 'A' ? "B" : "A")
                + signature.substring(1);

        String tamperedToken =
                parts[0] + "." + parts[1] + "." + modifiedSignature;

        assertFalse(jwtUtil.isAccessTokenValid(tamperedToken));
    }

    @Test
    void shouldRejectNullAndInvalidTokens() {
        JwtUtil jwtUtil = new JwtUtil(TEST_SECRET, 900000, 604800000);

        assertFalse(jwtUtil.isAccessTokenValid(null));
        assertFalse(jwtUtil.isAccessTokenValid(""));
        assertFalse(jwtUtil.isAccessTokenValid("invalid-token"));
        assertFalse(jwtUtil.isRefreshTokenValid(null));
    }
}

