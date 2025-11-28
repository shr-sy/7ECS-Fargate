# ---- Base Image ----
FROM node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Only Package Files First (for Docker caching) ----
COPY package*.json ./

# ---- Install Dependencies ----
RUN npm ci --only=production

# ---- Copy Source Code ----
COPY . .

# ---- Expose Service Port ----
EXPOSE 3000

# ---- Start Service ----
CMD ["npm", "start"]
