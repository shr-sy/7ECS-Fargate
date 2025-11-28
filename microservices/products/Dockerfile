# ---- Base Image ----
FROM public.ecr.aws/docker/library/node:18-alpine

# ---- Set Working Directory ----
WORKDIR /app

# ---- Copy Only Dependency Files (Improves Docker Cache) ----
COPY package*.json ./

# ---- Install Production Dependencies ----
RUN npm install --omit=dev

# ---- Copy the Application Code ----
COPY . .

# ---- Expose the Port ----
EXPOSE 3000

# ---- Start the App ----
CMD ["npm", "start"]
