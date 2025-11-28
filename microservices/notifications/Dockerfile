# ---- Base Image ----
FROM node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Only Package Files First (for build caching) ----
COPY package*.json ./

# ---- Install Dependencies ----
RUN npm ci --only=production

# ---- Copy Source Code ----
COPY . .

# ---- Expose Port ----
EXPOSE 3000

# ---- Start Application ----
CMD ["npm", "start"]
