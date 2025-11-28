FROM public.ecr.aws/docker/library/node:18-alpine

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install production dependencies
RUN npm install --omit=dev

# Copy application source
COPY . .

# Expose the application port
EXPOSE 3000

# Start the service
CMD ["npm", "start"]
