
package com.example.authservice;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    private final SecretKey signingKey;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtUtil(
            @Value("${jwt.secret-base64}") String secretBase64,
            @Value("${jwt.expiration-ms:900000}") long accessExpirationMs,
            @Value("${jwt.refresh-expiration-ms:604800000}") long refreshExpirationMs) {

        byte[] keyBytes = Decoders.BASE64.decode(secretBase64);

        this.signingKey = Keys.hmacShaKeyFor(keyBytes);
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;

        if (accessExpirationMs <= 0 || refreshExpirationMs <= 0) {
            throw new IllegalArgumentException(
                    "JWT expiration values must be positive"
            );
        }
    }

    public String generateToken(String email) {
        return generateAccessToken(email);
    }

    public String generateAccessToken(String email) {
        return generateToken(email, "access", accessExpirationMs);
    }

    public String generateRefreshToken(String email) {
        return generateToken(email, "refresh", refreshExpirationMs);
    }

    private String generateToken(
            String email,
            String tokenType,
            long expirationMs) {

        Date now = new Date();

        return Jwts.builder()
                .setSubject(email)
                .claim("token_type", tokenType)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + expirationMs))
                .signWith(signingKey, SignatureAlgorithm.HS256)
                .compact();
    }

    public boolean isTokenValid(String token) {
        return isAccessTokenValid(token);
    }

    public boolean isAccessTokenValid(String token) {
        return isTokenTypeValid(token, "access");
    }

    public boolean isRefreshTokenValid(String token) {
        return isTokenTypeValid(token, "refresh");
    }

    private boolean isTokenTypeValid(String token, String expectedType) {

        if (token == null || token.isBlank()) {
            return false;
        }

        try {
            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(signingKey)
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            return expectedType.equals(
                    claims.get("token_type", String.class)
            );

        } catch (JwtException | IllegalArgumentException ex) {
            return false;
        }
    }

    public String getEmailFromRefreshToken(String token) {

        if (!isRefreshTokenValid(token)) {
            throw new IllegalArgumentException("Invalid refresh token");
        }

        return Jwts.parserBuilder()
                .setSigningKey(signingKey)
                .build()
                .parseClaimsJws(token)
                .getBody()
                .getSubject();
    }
}

