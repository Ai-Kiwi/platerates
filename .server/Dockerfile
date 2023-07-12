# Use an official Node.js runtime as the base image
FROM node:18

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

#delete files for dev
RUN rm /usr/src/app/private.key && rm /usr/src/app/.env

# Expose the desired port
EXPOSE 3030

# Define the command to run the application
CMD [ "node", "index.js" ]

#command to build for in future when I am stupid
# sudo docker build -t toaster-server .

