FROM node:current-alpine3.16

RUN mkdir -p /home/app
WORKDIR /home/app
COPY app/ /home/app

RUN npm install

CMD [ "node", "/home/app/index.js" ]


 