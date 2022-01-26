#!/usr/bin/sh

mkdir -p $(pwd)/bin $(pwd)/src $(pwd)/tests

tee $(pwd)/bin/www.js <<'EOF'  > /dev/null
#!/usr/bin/env node

/**
 * Module dependencies.
 */
import http from 'http';
import app from '../src/index.js';

/**
 * Normalize a port into a number, string, or false.
 */
const normalizePort = (val) => {
  const port = parseInt(val, 10);

  if (Number.isNaN(port)) {
    // named pipe
    return val;
  }

  if (port >= 0) {
    // port number
    return port;
  }

  return false;
};

/**
 * Event listener for HTTP server "error" event.
 */
const onError = (error) => {
  if (error.syscall !== "listen") {
    throw error;
  }

  const bind = typeof port === "string" ? `Pipe ${port}` : `Port ${port}`;

  // handle specific listen errors with friendly messages
  switch (error.code) {
    case "EACCES":
      console.error(`${bind} requires elevated privileges`);
      process.exit(1);
      break;
    case "EADDRINUSE":
      console.error(`${bind} is already in use`);
      process.exit(1);
      break;
    default:
      throw error;
  }
};

/**
 * Event listener for HTTP server "listening" event.
 */
const onListening = () => {
  const addr = server.address();
  const bind = typeof addr === "string" ? `pipe ${addr}` : `port ${addr.port}`;
};

/**
 * Get port from environment and store in Express.
 */
const port = normalizePort(process.env.PORT || "3001");
app.set("port", port);

/**
 * Create HTTP server.
 */
const server = http.createServer(app);

/**
 * Listen on provided port, on all network interfaces.
 */
server.listen(port);
server.on("error", onError);
server.on("listening", onListening);
EOF

tee $(pwd)/src/index.js <<'EOF' > /dev/null
import express from 'express';

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: false }));

app.use('/', (req, res) => {
  res.json({ resource: 'api' });
});

// catch 404 and forward to error handler
app.use((req, res, next) => {
  next(new Error('404'));
});

// error handler
app.use((err, req, res, next) => {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

export default app;
EOF

tee $(pwd)/tests/index.test.js <<'EOF' > /dev/null
import supertest from "supertest";
import app from "../src/index.js";

describe("Base Endpoints", () => {
  it("tests base endpoint", async () => {
    const res = await supertest(app).get("/");
    expect(res.statusCode).toEqual(200);
  });
});

describe("API Endpoints", () => {
  it("tests api endpoint", async () => {
    const res = await supertest(app).get("/api");
    expect(res.statusCode).toEqual(200);
    expect(res.body.resource).toBe("api");
  });
});

describe("Test Jest Config", () => {
  it("Testing jest setup and config", () => {
    expect(1).toBe(1);
  });
});
EOF

tee $(pwd)/.prettierignore <<'EOF' > /dev/null
node_modules/
.yarn/
dist
EOF

tee $(pwd)/.eslintrc <<'EOF' > /dev/null
{
  "env": {
    "node": true,
    "es2021": true
  },
  "extends": [
    "airbnb-base",
    "plugin:prettier/recommended"
  ],
  "plugins": [
    "prettier",
  ],
  "ignorePatterns": [
    "**/*.test.js"
  ],
  "rules": {
    "prettier/prettier": "error",
    "no-unused-vars": [
      "error",
      {
        "argsIgnorePattern": "err|req|next"
      }
    ]
  },
  "parserOptions": {
    "ecmaVersion": 2021,
    "sourceType": "module",
    "ecmaFeatures": {
      "jsx": true
    }
  }
}
EOF

tee $(pwd)/.gitignore <<'EOF' > /dev/null
# See https://help.github.com/articles/ignoring-files/ for more about ignoring files.

# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# production
/build

# misc
.DS_Store
.env.local
.env.development.local
.env.test.local
.env.production.local

npm-debug.log*
yarn-debug.log*
yarn-error.log*

# non Zero-Installs - https://yarnpkg.com/getting-started/qa#which-files-should-be-gitignored
.pnp.*
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/sdks
!.yarn/versions
EOF

tee $(pwd)/Dockerfile <<'EOF' > /dev/null
FROM node:17-alpine as node

FROM node as builder

WORKDIR /api

COPY package*.json ./

RUN yarn install --production

# second stage
FROM node as final

ARG GIT_COMMIT=
ARG BUILD_DATE=
ARG VERSION=
ARG PORT=4001
ARG SOURCE=https://github.com/kevinedwards/ke-api.git
ARG NODE_ENV=production

LABEL com.kevinedwards.ke-api.revision=$GIT_COMMIT
LABEL com.kevinedwards.ke-api.created=$BUILD_DATE
LABEL com.kevinedwards.ke-api.source=$SOURCE
LABEL com.kevinedwards.ke-api.version=$VERSION
LABEL com.kevinedwards.ke-api.vendor="Kevin Edwards"
LABEL com.kevinedwards.ke-api.authors="Kevin Edwards <kedwards@kevinedwards.com"

# Update the system
RUN apk --no-cache -U upgrade

WORKDIR /home/node/api/

USER node

COPY --chown=node:node --from=builder /api/node_modules ./node_modules

COPY --chown=node:node . .

EXPOSE $PORT

CMD [ "node", "bin/www" ]
EOF

tee $(pwd)/.prettierrc <<'EOF' > /dev/null
{
  "singleQuote": true,
  "trailingComma": "all",
  "printWidth": 120,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
EOF

touch $(pwd)/CHANGELOG.md

echo '# KE-API' > $(pwd)/README.md

# yarn set version berry > /dev/null

tee $(pwd)/package.json <<'EOF' > /dev/null
{
  "name": "ke-api",
  "description": "KE-API",
  "repository": "https://github.com/kevinedwards/ke-api.git",
  "author": "Kevin Edwards",
  "license": "UNLICENSED",
  "private": true,
  "type": "module",
  "version": "0.0.0",
  "scripts": {
    "fmt": "prettier --write './src/**/*.js'",
    "lint": "eslint './src/**/*.js'",
    "lint:fix": "eslint --fix './src/**/*.js'",
    "start": "nodemon ./bin/www.js",
    "test": "node --experimental-vm-modules node_modules/.bin/jest",
    "test:watch": "node --experimental-vm-modules node_modules/.bin/jest --watchAll",
    "debug": "nodemon --exec \"node --inspect=0.0.0.0:9229 ./bin/www/\""
  },
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.+(js|jsx)": [
      "eslint --fix",
      "git add"
    ],
    "*(css,json,md,yaml,yml)": [
      "npm format",
      "git add"
    ]
  }
}
EOF

# tee $(pwd)/.yarnrc.yml <<'EOF'  > /dev/null
# yarnPath: .yarn/releases/yarn-3.1.0.cjs

# # using ES6 import/export which is not yet supported in yarn3
# nodeLinker: node-modules
# EOF

npm i express > /dev/null

npm i --save-dev \
prettier \
  jest \
  nodemon \
  husky \
  supertest \
  eslint \
  eslint-config-airbnb-base \
  eslint-config-prettier \
  eslint-plugin-import \
  eslint-plugin-prettier > /dev/null