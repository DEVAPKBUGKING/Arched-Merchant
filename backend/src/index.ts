import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import rateLimit from '@fastify/rate-limit';

import { env } from './env.js';
import { healthRoutes } from './routes/health.js';

const app = Fastify({
  logger: {
    level: env.LOG_LEVEL,
  },
  trustProxy: true,
});

await app.register(helmet, {
  contentSecurityPolicy: false,
});

await app.register(cors, {
  origin: env.CORS_ORIGIN === '*' ? true : env.CORS_ORIGIN.split(','),
  credentials: true,
});

await app.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute',
});

await app.register(healthRoutes, { prefix: '/api' });

app.setNotFoundHandler((req, reply) => {
  reply.code(404).send({ error: 'not_found', path: req.url });
});

app.setErrorHandler((err, req, reply) => {
  req.log.error({ err }, 'request failed');
  const status = err.statusCode && err.statusCode >= 400 ? err.statusCode : 500;
  reply.code(status).send({
    error: err.code ?? 'internal_error',
    message: env.NODE_ENV === 'production' && status === 500
      ? 'internal server error'
      : err.message,
  });
});

const start = async () => {
  try {
    await app.listen({ port: env.PORT, host: '0.0.0.0' });
    app.log.info(`ARCHED MERCHANT backend listening on :${env.PORT}`);
  } catch (err) {
    app.log.error(err);
    process.exit(1);
  }
};

start();
