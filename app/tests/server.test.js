import request from 'supertest'
import app from '../src/server.js'

describe('web-app', () => {
  test('health returns ok', async () => {
    const res = await request(app).get('/health')
    expect(res.statusCode).toBe(200)
    expect(res.body.status).toBe('ok')
  })
})
