# ASM-Hawk Web Dockerfile (Next.js)
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Next.js dev server port - using 3101 for consistency
ENV PORT=3101

# Expose port
EXPOSE 3101

# Start the application in development mode on port 3101
CMD ["npx", "next", "dev", "-p", "3101", "-H", "0.0.0.0"]
