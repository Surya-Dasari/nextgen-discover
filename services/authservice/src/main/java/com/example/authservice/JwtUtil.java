
package com.example.authservice;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.Date;

@Component
public class JwtUtil {

    private final PrivateKey signingKey;
    private final PublicKey verificationKey;
    private final String issuer;
    private final String audience;
    private final long accessExpirationMs;
    private final long refreshExpirationMs;

    public JwtUtil(
            @Value("${jwt.private-key-path}") String privateKeyPath,
            @Value("${jwt.public-key-path}") String publicKeyPath,
            @Value("${jwt.issuer}") String issuer,
            @Value("${jwt.audience}") String audience,
            @Value("${jwt.expiration-ms:900000}") long accessExpirationMs,
            @Value("${jwt.refresh-expiration-ms:604800000}") long refreshExpirationMs) {

        this.signingKey = loadPrivateKey(privateKeyPath);
        this.verificationKey = loadPublicKey(publicKeyPath);
        this.issuer = issuer;
        this.audience = audience;
        this.accessExpirationMs = accessExpirationMs;
        this.refreshExpirationMs = refreshExpirationMs;

        if (issuer == null || issuer.isBlank()
                || audience == null || audience.isBlank()) {
            throw new IllegalArgumentException(
                    "JWT issuer and audience must not be empty");
        }

        if (accessExpirationMs <= 0 || refreshExpirationMs <= 0) {
            throw new IllegalArgumentException(
                    "JWT expiration values must be positive");
        }
    }

    private PrivateKey loadPrivateKey(String path) {
        try {
            String pem = Files.readString(Path.of(path));
            String encoded = pem
                    .replace("-----BEGIN PRIVATE KEY-----", "")
                    .replace("-----END PRIVATE KEY-----", "")
                    .replaceAll("\\s", "");

            byte[] keyBytes = Base64.getDecoder().decode(encoded);

            return KeyFactory.getInstance("RSA")
                    .generatePrivate(new PKCS8EncodedKeySpec(keyBytes));

        } catch (Exception ex) {
            throw new IllegalStateException(
                    "Unable to load JWT RSA private key", ex);
        }
    }

    private PublicKey loadPublicKey(String path) {
        try {
            String pem = Files.readString(Path.of(path));
            String encoded = pem
                    .replace("-----BEGIN PUBLIC KEY-----", "")
                    .replace("-----END PUBLIC KEY-----", "")
                    .replaceAll("\\s", "");

            byte[] keyBytes = Base64.getDecoder().decode(encoded);

            return KeyFactory.getInstance("RSA")
                    .generatePublic(new X509EncodedKeySpec(keyBytes));

        } catch (Exception ex) {
            throw new IllegalStateException(
                    "Unable to load JWT RSA public key", ex);
        }
    }

    public String generateToken(String email) {
        return generateAccessToken(email);
    }

    // Legacy overload retained for existing callers and tests.
    public String generateAccessToken(String email) {
        return generateToken(email, null, "access", accessExpirationMs);
    }

    // Access token containing the authenticated database user ID.
    public String generateAccessToken(String email, Long userId) {

        validateUserId(userId);

        return generateToken(email, userId, "access", accessExpirationMs);
    }

    // Legacy overload retained for compatibility.
    public String generateRefreshToken(String email) {
        return generateToken(email, null, "refresh", refreshExpirationMs);
    }

    // Refresh token containing the authenticated database user ID.
    public String generateRefreshToken(String email, Long userId) {

        validateUserId(userId);

        return generateToken(email, userId, "refresh", refreshExpirationMs);
    }

    private void validateUserId(Long userId) {
        if (userId == null || userId <= 0) {
            throw new IllegalArgumentException("Invalid user ID");
        }
    }

    private String generateToken(
            String email,
            Long userId,
            String tokenType,
            long expirationMs) {

        if (email == null || email.isBlank()) {
            throw new IllegalArgumentException("Email must not be empty");
        }

        Date now = new Date();

        var builder = Jwts.builder()
                .setSubject(email)
                .setIssuer(issuer)
                .setAudience(audience)
                .claim("token_type", tokenType)
                .setIssuedAt(now)
                .setExpiration(new Date(now.getTime() + expirationMs));

        if (userId != null) {
            builder.claim("userId", userId);
        }

        return builder
                .signWith(signingKey, SignatureAlgorithm.RS256)
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

    private Claims parseToken(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(verificationKey)
                .requireIssuer(issuer)
                .requireAudience(audience)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    private boolean isTokenTypeValid(String token, String expectedType) {

        if (token == null || token.isBlank()) {
            return false;
        }

        try {
            Claims claims = parseToken(token);

            return expectedType.equals(
                    claims.get("token_type", String.class));

        } catch (JwtException | IllegalArgumentException ex) {
            return false;
        }
    }

    public String getEmailFromRefreshToken(String token) {

        if (!isRefreshTokenValid(token)) {
            throw new IllegalArgumentException("Invalid refresh token");
        }

        return parseToken(token).getSubject();
    }

    public Long getUserIdFromRefreshToken(String token) {

        if (!isRefreshTokenValid(token)) {
            throw new IllegalArgumentException("Invalid refresh token");
        }

        Object rawUserId = parseToken(token).get("userId");

        if (!(rawUserId instanceof Number number)
                || number.longValue() <= 0) {
            throw new IllegalArgumentException(
                    "Refresh token does not contain a valid user ID");
        }

        return number.longValue();
    }
}

