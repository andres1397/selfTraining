FROM node:17-alpine3.12

WORKDIR /app
COPY . .
RUN cd /app/movie-analyst-api ; npm install

CMD ["node", "/app/movie-analyst-api/server.js"]