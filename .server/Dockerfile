# Use an official Node.js runtime as the base image
FROM node:18-alpine
#FROM node:18

WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the application code
COPY build/ .

#copys the web build into it
COPY ./web/ ./web/

#copy over android build
COPY ./app-release.apk ./toaster.apk

#can't get rid of this idk why
ENTRYPOINT []

#delete files for dev
#RUN rm /usr/src/app/private.key && rm /usr/src/app/.env

# Expose the desired port
EXPOSE 3030

# Define the command to run the application
CMD [ "node", "index.js" ]

#command to build for in future when I am stupid
# sudo docker build -t toaster-server .

