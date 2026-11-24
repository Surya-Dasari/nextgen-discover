
package com.example.authservice;

import io.jsonwebtoken.Jwts;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.util.Base64;

import static org.junit.jupiter.api.Assertions.*;

class JwtUtilTest {

    private static final String ISSUER = "nextgen-discover-auth";
    private static final String AUDIENCE = "nextgen-discover-api";

    @TempDir
    Path tempDir;

    private Path privateKeyPath;
    private Path publicKeyPath;
    private KeyPair keyPair;

    @BeforeEach
    void setUp() throws Exception {

        KeyPairGenerator generator = KeyPairGenerator.getInstance("RSA");
        generator.initialize(2048);

        keyPair = generator.generateKeyPair();

        privateKeyPath = tempDir.resolve("private.pem");
        publicKeyPath = tempDir.resolve("public.pem");

        Files.writeString(
                privateKeyPath,
                toPem("PRIVATE KEY", keyPair.getPrivate().getEncoded())
        );

        Files.writeString(
                publicKeyPath,
                toPem("PUBLIC KEY", keyPair.getPublic().getEncoded())
        );
    }

    private String toPem(String type, byte[] encoded) {

        String base64 = Base64.getMimeEncoder(
                64,
                new byte[]{'\n'}
        ).encodeToString(encoded);

        return "-----BEGIN " + type + "-----\n"
                + base64
                + "\n-----END " + type + "-----\n";
    }

    private JwtUtil createJwtUtil(
            long accessExpiration,
            long refreshExpiration) {

        return new JwtUtil(
                privateKeyPath.toString(),
                publicKeyPath.toString(),
                ISSUER,
                AUDIENCE,
                accessExpiration,
                refreshExpiration
        );
    }

    @Test
    void shouldGenerateAccessToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String token = jwtUtil.generateAccessToken("testuser");

        assertNotNull(token);
        assertEquals(3, token.split("\\.").length);
        assertTrue(jwtUtil.isAccessTokenValid(token));
    }

    @Test
    void shouldGenerateRefreshToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String token = jwtUtil.generateRefreshToken("testuser");

        assertNotNull(token);
        assertTrue(jwtUtil.isRefreshTokenValid(token));
    }

    @Test
    void shouldGenerateRs256TokenWithRequiredClaims() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String token = jwtUtil.generateAccessToken("testuser");

        String[] parts = token.split("\\.");

        String header = new String(
                Base64.getUrlDecoder().decode(parts[0])
        );

        assertTrue(header.contains("\"alg\":\"RS256\""));

        var claims = Jwts.parserBuilder()
                .setSigningKey(keyPair.getPublic())
                .requireIssuer(ISSUER)
                .requireAudience(AUDIENCE)
                .build()
                .parseClaimsJws(token)
                .getBody();

        assertEquals("testuser", claims.getSubject());
        assertEquals("access", claims.get("token_type"));
        assertEquals(ISSUER, claims.getIssuer());
        assertEquals(AUDIENCE, claims.getAudience());

        assertNotNull(claims.getIssuedAt());
        assertNotNull(claims.getExpiration());

        assertTrue(jwtUtil.isAccessTokenValid(token));
    }

    @Test
    void shouldRejectRefreshTokenAsAccessToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String refreshToken = jwtUtil.generateRefreshToken("testuser");

        assertFalse(jwtUtil.isAccessTokenValid(refreshToken));
    }

    @Test
    void shouldRejectAccessTokenAsRefreshToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String accessToken = jwtUtil.generateAccessToken("testuser");

        assertFalse(jwtUtil.isRefreshTokenValid(accessToken));
    }

    @Test
    void shouldExtractEmailFromRefreshToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String refreshToken = jwtUtil.generateRefreshToken("testuser");

        assertEquals(
                "testuser",
                jwtUtil.getEmailFromRefreshToken(refreshToken)
        );
    }

    @Test
    void shouldAcceptValidAccessToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String token = jwtUtil.generateToken("testuser");

        assertTrue(jwtUtil.isTokenValid(token));
    }

    @Test
    void shouldRejectExpiredAccessToken() throws InterruptedException {

        JwtUtil jwtUtil = createJwtUtil(1000, 604800000);

        String token = jwtUtil.generateAccessToken("testuser");

        Thread.sleep(2500);

        assertFalse(jwtUtil.isAccessTokenValid(token));
    }

    @Test
    void shouldRejectExpiredRefreshToken() throws InterruptedException {

        JwtUtil jwtUtil = createJwtUtil(900000, 1000);

        String token = jwtUtil.generateRefreshToken("testuser");

        Thread.sleep(2500);

        assertFalse(jwtUtil.isRefreshTokenValid(token));
    }

    @Test
    void shouldRejectTamperedToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

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

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        assertFalse(jwtUtil.isAccessTokenValid(null));
        assertFalse(jwtUtil.isAccessTokenValid(""));
        assertFalse(jwtUtil.isAccessTokenValid("invalid-token"));
        assertFalse(jwtUtil.isRefreshTokenValid(null));
    }

    // New identity claim tests

    @Test
    void shouldIncludeUserIdInAccessToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String token = jwtUtil.generateAccessToken("testuser", 42L);

        var claims = Jwts.parserBuilder()
                .setSigningKey(keyPair.getPublic())
                .requireIssuer(ISSUER)
                .requireAudience(AUDIENCE)
                .build()
                .parseClaimsJws(token)
                .getBody();

        assertEquals(42L, ((Number) claims.get("userId")).longValue());
        assertEquals("testuser", claims.getSubject());
        assertEquals("access", claims.get("token_type"));
    }

    @Test
    void shouldIncludeUserIdInRefreshToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String token = jwtUtil.generateRefreshToken("testuser", 42L);

        assertEquals(42L, jwtUtil.getUserIdFromRefreshToken(token));
        assertEquals("testuser", jwtUtil.getEmailFromRefreshToken(token));
        assertTrue(jwtUtil.isRefreshTokenValid(token));
    }

    @Test
    void shouldRejectRefreshTokenWithoutUserId() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        String legacyToken = jwtUtil.generateRefreshToken("testuser");

        assertThrows(
                IllegalArgumentException.class,
                () -> jwtUtil.getUserIdFromRefreshToken(legacyToken)
        );
    }

    @Test
    void shouldRejectInvalidUserIdWhenGeneratingAccessToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        assertThrows(
                IllegalArgumentException.class,
                () -> jwtUtil.generateAccessToken("testuser", 0L)
        );
    }

    @Test
    void shouldRejectInvalidUserIdWhenGeneratingRefreshToken() {

        JwtUtil jwtUtil = createJwtUtil(900000, 604800000);

        assertThrows(
                IllegalArgumentException.class,
                () -> jwtUtil.generateRefreshToken("testuser", -1L)
        );
    }
}

