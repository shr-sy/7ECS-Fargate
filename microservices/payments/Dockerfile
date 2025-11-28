# ---- Base Image ----
FROM public.ecr.aws/docker/library/node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Only Dependency Files (for caching) ----
COPY package*.json ./

# ---- Install Production Dependencies ----
RUN npm ci --only=production

# ---- Copy Application Code ----
COPY . .

# ---- Expose App Port ----
EXPOSE 3000

# ---- Start App ----
CMD ["npm", "start"]
