# ---- Base Image ----
FROM public.ecr.aws/docker/library/node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Only Package Files First (for Docker caching) ----
COPY package*.json ./

# ---- Install Dependencies (compatible with no lockfile) ----
RUN npm install --omit=dev

# ---- Copy Source Code ----
COPY . .

# ---- Expose Service Port ----
EXPOSE 3000

# ---- Start Service ----
CMD ["npm", "start"]
