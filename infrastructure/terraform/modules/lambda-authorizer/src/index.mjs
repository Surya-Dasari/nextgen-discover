
import crypto from "node:crypto";

const unauthorized = () => {
  throw new Error("Unauthorized");
};

function decodeBase64Url(value) {
  return Buffer.from(value, "base64url");
}

function parseJwt(token) {
  const parts = token.split(".");

  if (parts.length !== 3 || parts.some((part) => !part)) {
    unauthorized();
  }

  try {
    return {
      header: JSON.parse(decodeBase64Url(parts[0]).toString("utf8")),
      claims: JSON.parse(decodeBase64Url(parts[1]).toString("utf8")),
      signature: decodeBase64Url(parts[2]),
      signingInput: `${parts[0]}.${parts[1]}`,
    };
  } catch {
    unauthorized();
  }
}

function validateJwt(token) {
  const { header, claims, signature, signingInput } = parseJwt(token);

  if (header.alg !== "RS256") unauthorized();

  if (header.crit !== undefined) unauthorized();

  const publicKey = process.env.JWT_PUBLIC_KEY;
  const issuer = process.env.JWT_ISSUER;
  const audience = process.env.JWT_AUDIENCE;

  if (!publicKey || !issuer || !audience) {
    throw new Error("Authorizer configuration is incomplete");
  }

  let validSignature;

  try {
    validSignature = crypto.verify(
      "RSA-SHA256",
      Buffer.from(signingInput, "utf8"),
      publicKey.replace(/\\n/g, "\n"),
      signature
    );
  } catch {
    unauthorized();
  }

  if (!validSignature) unauthorized();

  const now = Math.floor(Date.now() / 1000);

  if (
    typeof claims.exp !== "number" ||
    !Number.isFinite(claims.exp) ||
    now >= claims.exp
  ) {
    unauthorized();
  }

  if (
    claims.nbf !== undefined &&
    (
      typeof claims.nbf !== "number" ||
      !Number.isFinite(claims.nbf) ||
      now < claims.nbf
    )
  ) {
    unauthorized();
  }

  if (
    typeof claims.iat !== "number" ||
    !Number.isFinite(claims.iat) ||
    claims.iat > now + 60
  ) {
    unauthorized();
  }

  if (claims.iss !== issuer) unauthorized();

  const tokenAudiences = Array.isArray(claims.aud)
    ? claims.aud
    : [claims.aud];

  if (!tokenAudiences.includes(audience)) unauthorized();

  if (claims.token_type !== "access") unauthorized();

  if (typeof claims.sub !== "string" || !claims.sub.trim()) {
    unauthorized();
  }

  // Require a valid numeric database user ID.
  if (
    typeof claims.userId !== "number" ||
    !Number.isSafeInteger(claims.userId) ||
    claims.userId <= 0
  ) {
    unauthorized();
  }

  return claims;
}

function buildPolicy(principalId, effect, resource) {
  return {
    principalId,
    policyDocument: {
      Version: "2012-10-17",
      Statement: [
        {
          Action: "execute-api:Invoke",
          Effect: effect,
          Resource: resource,
        },
      ],
    },
  };
}

export const handler = async (event) => {
  try {
    const authorizationToken = event.authorizationToken;

    if (
      typeof authorizationToken !== "string" ||
      !authorizationToken.startsWith("Bearer ")
    ) {
      unauthorized();
    }

    const token = authorizationToken.slice(7).trim();

    if (!token) unauthorized();

    const claims = validateJwt(token);

    return {
      ...buildPolicy(claims.sub, "Allow", event.methodArn),
      context: {
        tokenType: claims.token_type,
        userId: String(claims.userId),
        subject: claims.sub,
      },
    };
  } catch (error) {
    if (error.message === "Unauthorized") {
      throw error;
    }

    console.error("JWT authorizer execution failed");
    throw new Error("Unauthorized");
  }
};

