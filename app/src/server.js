import express from "express";
const app = express();
const PORT = process.env.PORT || 8080;
const WEB_MESSAGE = process.env.WEB_MESSAGE || "Hello from default";
app.get("/health", (_req, res) => res.status(200).json({ status: "ok" }));
app.get("/", (_req, res) => res.status(200).json({ message: WEB_MESSAGE }));
app.listen(PORT, () => console.log(`Server up on ${PORT}`));
export default app;