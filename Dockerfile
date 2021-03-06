#Create an alias for the container built from the node:alpine base image
FROM node:alpine as builder

#Setting the working directory inside the container to be the same name as our app on our local machine.
WORKDIR "/my-static-app"

#Copying our package.json file from our local machine to the working directory inside the docker container.
COPY package.json ./
COPY entrypoint.sh ./

RUN chmod +x entrypoint.sh
#Installing the dependencies listed in our package.json file.
RUN npm install

#Copying our project files from our local machine to the working directory in our container.
COPY . .

#Create the production build version of the  react app
RUN npm run build

#Create a new container from a linux base image that has the aws-cli installed
FROM mesosphere/aws-cli

#Using the alias defined for the first container, copy the contents of the build folder to this container
COPY --from=builder /my-static-app/dist .

#Set the default command of this container to push the files from the working directory of this container to our s3 bucket 
# CMD ["s3", "sync", "./", "http://as-app.s3-website-us-east-1.amazonaws.com"]   
# RUN apt-get update \
#     && apt-get install -y --no-install-recommends build-essential

FROM python:3.7-alpine

ENV AWSCLI_VERSION='1.16.265'
RUN pip install --quiet --no-cache-dir awscli==${AWSCLI_VERSION}
COPY entrypoint.sh ./
RUN ["chmod", "+x", "/entrypoint.sh"]
ENTRYPOINT ["/entrypoint.sh"]

