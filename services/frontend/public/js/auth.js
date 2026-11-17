
const API = "http://localhost:9003/api";

async function login() {
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;
  const msg = document.getElementById("msg");

  try {
    const response = await fetch(`${API}/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    });

    const result = await response.text();

    if (!response.ok) {
      msg.innerText = result || "Login failed";
      return;
    }

    const tokens = JSON.parse(result);

    if (!tokens.accessToken || !tokens.refreshToken) {
      msg.innerText = "Invalid authentication response";
      return;
    }

    localStorage.setItem("accessToken", tokens.accessToken);
    localStorage.setItem("refreshToken", tokens.refreshToken);

    // Temporary compatibility for pages still using the old key.
    localStorage.setItem("token", tokens.accessToken);

    window.location.href = "welcome.html";

  } catch (error) {
    console.error("Login error:", error);
    msg.innerText = "Unable to connect to the server";
  }
}

async function signup() {
  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;
  const msg = document.getElementById("msg");

  try {
    const response = await fetch(`${API}/signup`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password })
    });

    const message = await response.text();

    msg.innerText = message;

  } catch (error) {
    console.error("Signup error:", error);
    msg.innerText = "Unable to connect to the server";
  }
}

