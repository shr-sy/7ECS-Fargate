# ---- Base Image ----
FROM public.ecr.aws/docker/library/node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Only Package Files First (for better caching) ----
COPY package*.json ./

# ---- Install Dependencies (no package-lock required) ----
RUN npm install --omit=dev

# ---- Copy Application Files ----
COPY . .

# ---- Expose App Port ----
EXPOSE 3000

# ---- Start Application ----
CMD ["npm", "start"]
