import express from 'express'
// PR demo: no behavior change
const app = express()
const PORT = process.env.PORT || 8080
const WEB_MESSAGE = process.env.WEB_MESSAGE || 'Hello from default'
app.get('/health', (_req, res) => res.status(200).json({ status: 'ok' }))
app.get('/', (_req, res) => res.status(200).json({ message: WEB_MESSAGE }))
// Only start the server when not under Jest to avoid open handles in tests
const server = process.env.JEST_WORKER_ID ? null : app.listen(PORT, () => console.log(`Server up on ${PORT}`))
export default app
export { server }
