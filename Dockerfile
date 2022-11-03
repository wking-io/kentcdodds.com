# Fetch the LiteFS binary using a multi-stage build.
# FROM flyio/litefs:sha-887ba87 AS litefs

# base node image
FROM node:18-bullseye-slim as base

# install open ssl and sqlite3 for prisma
# ffmpeg for the call kent functionality
# ca-certificates and fuse for litefs
RUN apt-get update && apt-get install -y fuse openssl ffmpeg sqlite3 ca-certificates

# install all node_modules, including dev
FROM base as deps

RUN mkdir /app/
WORKDIR /app/

ADD package.json .npmrc package-lock.json ./
ADD other/patches ./other/patches
RUN npm install

# setup production node_modules
FROM base as production-deps

RUN mkdir /app/
WORKDIR /app/

COPY --from=deps /app/node_modules /app/node_modules
ADD package.json .npmrc package-lock.json /app/
RUN npm prune --omit=dev

# build app
FROM base as build

ARG COMMIT_SHA
ENV COMMIT_SHA=$COMMIT_SHA

RUN mkdir /app/
WORKDIR /app/

COPY --from=deps /app/node_modules /app/node_modules

ADD other/runfile.js /app/other/runfile.js

# schema doesn't change much so these will stay cached
ADD prisma /app/prisma
ADD prisma-postgres /app/prisma-postgres

RUN npx prisma generate
RUN npx prisma generate --schema ./prisma-postgres/schema.prisma

# app code changes all the time
ADD . .
RUN npm run build

# build smaller image for running
FROM base

ENV DATABASE_URL=file:/data/sqlite.db
# ENV DATABASE_URL=file:/litefs/data/sqlite.db
ENV NODE_ENV=production
# Make SQLite CLI accessible
RUN echo "#!/bin/sh\nset -x\nsqlite3 \$DATABASE_URL" > /usr/local/bin/database-cli && chmod +x /usr/local/bin/database-cli

RUN mkdir /app/
WORKDIR /app/

COPY --from=production-deps /app/node_modules /app/node_modules
COPY --from=build /app/node_modules/.prisma /app/node_modules/.prisma
COPY --from=build /app/node_modules/@prisma/client-postgres /app/node_modules/@prisma/client-postgres
COPY --from=build /app/build /app/build
COPY --from=build /app/public /app/public
COPY --from=build /app/server-build /app/server-build
COPY --from=build /app/other/runfile.js /app/other/runfile.js

# prepare for litefs
# COPY --from=litefs /usr/local/bin/litefs /usr/local/bin/litefs
# ADD other/litefs.yml /etc/litefs.yml
# RUN mkdir -p /data /litefs/data

ADD . .

# ENTRYPOINT "litefs"
CMD ["bash", "start.sh"]