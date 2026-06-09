export const throttlerConfig = () => ({
  throttlers: [
    {
      ttl: 60000,
      limit: 100,
    },
  ],
});
