export const jwtConfig = () => ({
  secret:
    process.env.JWT_SECRET ||
    'fallback-dev-secret-change-in-production-32chars',
  expiresIn: process.env.JWT_EXPIRES_IN || '15m',
  refreshSecret:
    process.env.JWT_REFRESH_SECRET ||
    'fallback-dev-refresh-secret-change-in-production-32chars',
  refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
});
