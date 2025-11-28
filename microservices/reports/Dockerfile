# ---- Base Image ----
FROM public.ecr.aws/docker/library/node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Dependency Files ----
COPY package*.json ./

# ---- Install Production Dependencies ----
RUN npm install --omit=dev

# ---- Copy Application Source ----
COPY . .

# ---- Expose Port ----
EXPOSE 3000

# ---- Start App ----
CMD ["npm", "start"]
