
const express = require("express");
const path = require("path");
const http = require("http");
const https = require("https");

const app = express();

const PORT = Number(process.env.PORT || 9080);

const API_GATEWAY_URL = new URL(
  process.env.API_GATEWAY_URL ||
    "https://tyug42sb9j.execute-api.us-east-2.amazonaws.com/dev"
);

if (!["http:", "https:"].includes(API_GATEWAY_URL.protocol)) {
  throw new Error("API_GATEWAY_URL must use HTTP or HTTPS");
}

const proxyTransport =
  API_GATEWAY_URL.protocol === "https:" ? https : http;

app.get("/config.js", (req, res) => {
  const apiBaseUrl = process.env.API_BASE_URL || "/api";

  res.type("application/javascript").send(
    `window.APP_CONFIG = ${JSON.stringify({ apiBaseUrl })};`
  );
});

// Reverse proxy: Browser -> Frontend -> API Gateway
app.use("/api", (req, res) => {
  const proxyPath = req.originalUrl.replace(/^\/api/, "") || "/";

  const basePath = API_GATEWAY_URL.pathname.replace(/\/+$/, "");

  const targetPath =
    `${basePath}${proxyPath.startsWith("/") ? proxyPath : `/${proxyPath}`}`;

  const proxyRequest = proxyTransport.request(
    {
      hostname: API_GATEWAY_URL.hostname,
      port: API_GATEWAY_URL.port || undefined,
      path: targetPath,
      method: req.method,
      headers: {
        ...req.headers,
        host: API_GATEWAY_URL.host
      }
    },
    (proxyResponse) => {
      res.writeHead(
        proxyResponse.statusCode || 502,
        proxyResponse.headers
      );

      proxyResponse.pipe(res);
    }
  );

  proxyRequest.on("error", (error) => {
    console.error("API Gateway proxy error:", error.message);

    if (!res.headersSent) {
      res.status(502).send("API Gateway unavailable");
    }
  });

  req.pipe(proxyRequest);
});

app.use(express.static(path.join(__dirname, "public")));

app.get("/health", (req, res) => {
  res.send("OK");
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`NextGen UI running on port ${PORT}`);
  console.log(`API Gateway target: ${API_GATEWAY_URL.origin}${API_GATEWAY_URL.pathname}`);
});

