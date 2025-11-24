const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.json({ service: "payments", status: "running", time: new Date() });
});

app.get("/health", (req, res) => res.send("OK"));

app.listen(PORT, () => console.log(`payments running on port ${PORT}`));
