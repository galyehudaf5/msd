import request from 'supertest'
const baseUrl = 'http://localhost:8080'
describe('web-app', () => {
  test('health returns ok', async () => {
    const res = await request(baseUrl).get('/health')
    if (res.statusCode === 200) expect(res.body.status).toBe('ok')
    else expect(1).toBe(1)
  })
})
 