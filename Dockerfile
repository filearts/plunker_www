FROM node:4

WORKDIR /src

COPY package.json /src/package.json

RUN npm install --production

COPY *.coffee *.js *.json /src/
COPY assets /src/assets/
COPY build /src/build/
COPY lib /src/lib/
COPY middleware /src/middleware/
COPY views /src/views/

EXPOSE 8080

ENV PORT 8080
ENV NODE_ENV production

CMD ["node", "server.js"]
