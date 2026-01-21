# ASM-Hawk API Dockerfile (NestJS Development)
FROM node:20-alpine

WORKDIR /app

# Install dependencies for Prisma and Docker CLI for scan execution
RUN apk add --no-cache openssl docker-cli

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy Prisma schema
COPY prisma ./prisma/

# Generate Prisma client
RUN npx prisma generate

# Copy source code (for development, this will be overridden by volume mount)
COPY . .

# Expose port
EXPOSE 3100

# Start the application in dev mode
CMD ["npm", "run", "start:dev"]
