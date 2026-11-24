FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source
COPY server.js ./
COPY routes/ ./routes/
COPY models/ ./models/

EXPOSE 3000

CMD ["node", "server.js"]
