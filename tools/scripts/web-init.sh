#!/usr/bin/sh

npx create-react-app web --template redux

# tee $(pwd)/public/index.html <<'EOF' > /dev/null
# <!doctype html>
# <html lang="en">
# <head>
#   <meta charset="utf-8"/>
#   <meta name="viewport" content="width=device-width, initial-scale=1" />
#   <title>Web</title>
# </head>
# <body>
#   <div id="root"></div>
# </body>
# </html>
# EOF

# tee $(pwd)/src/index.jsx <<'EOF' > /dev/null
# import React from 'react';
# import ReactDOM from 'react-dom';
# import App from './app/App';

# ReactDOM.render(
#   <React.StrictMode>
#     <App />
#   </React.StrictMode>,
#   document.getElementById('root'),
# );
# EOF

# tee $(pwd)/src/app/App.jsx <<'EOF' > /dev/null
# import React from 'react';

# const App = () => (
#   <div>
#     <h1>Hello React!</h1>
#   </div>
# );

# export default App;
# EOF

# tee $(pwd)/src/app/App.test.js <<'EOF' > /dev/null
# import React from 'react';
# import { render, screen } from '@testing-library/react';
# import { shallow } from 'enzyme';
# import App from './App';

# test('renders main app', () => {
#   render(<App />);
#   const element = screen.getByText(/Hello React/i);
#   expect(element).toBeInTheDocument();
# });

# describe('App', () => {
#   it('renders without crashing', () => {
#     const wrapper = shallow(<App />);
#     expect(wrapper).toBeTruthy();
#   });
# });
# EOF

# tee $(pwd)/tests/setupTests.js <<'EOF' > /dev/null
# // jest-dom adds custom jest matchers for asserting on DOM nodes.
# // allows you to do things like:
# // expect(element).toHaveTextContent(/react/i)
# // learn more: https://github.com/testing-library/jest-dom
# import '@testing-library/jest-dom';
# import { configure } from 'enzyme';
# import Adapter from '@wojtekmaj/enzyme-adapter-react-17';

# configure({ adapter: new Adapter() });
# EOF

# tee $(pwd)/.babelrc <<'EOF' > /dev/null
# {
#   "presets": [
#     "@babel/preset-env",
#     "@babel/preset-react"
#   ],
#   "plugins": ["@babel/plugin-transform-runtime"]
# }
# EOF

tee $(pwd)/.dockerignore $(pwd)/.prettierignore <<'EOF' > /dev/null
node_modules/
dist
EOF

tee $(pwd)/.prettierignore <<'EOF' > /dev/null
node_modules/
dist
EOF

tee $(pwd)/.eslintrc <<'EOF' > /dev/null
{
  "env": {
    "browser": true,
    "es2021": true,
    "jest": true
  },
  "extends": [
    "prettier",
    "plugin:jest/recommended",
    "plugin:jest/style",
    "airbnb",
    "airbnb/hooks"
  ],
  "plugins": [
    "react",
    "prettier",
    "jest"
  ],
  "ignorePatterns": [
    "**/*.test.js"
  ],
  "rules": {
    "prettier/prettier": [
      "error",
      {
        "singleQuote": true
      }
    ],
    "react/react-in-jsx-scope": "off",
    "no-param-reassign": [
      "error",
      {
        "props": true,
        "ignorePropertyModificationsFor": [
          "state"
        ]
      }
    ],
    "react/jsx-filename-extension": [
      "warn",
      {
        "extensions": [".js", ".jsx"]
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

tee $(pwd)/Dockerfile <<'EOF' > /dev/null
FROM node:17-alpine AS builder

WORKDIR /app

ENV PATH /app/node_modules/.bin:$PATH
COPY package*.json ./

ARG API_BASE_URL=http://localhost:3001
ENV REACT_APP_API_BASE_URL=$API_BASE_URL

RUN npm ci --production

COPY . .

RUN npm run build

# second stage
FROM nginx:stable-alpine

ARG GIT_COMMIT=
ARG BUILD_DATE=
ARG VERSION=
ARG SOURCE=https://github.com/kevinedwards/ke-web.git

LABEL com.kevinedwards.rtls-web.revision=$GIT_COMMIT
LABEL com.kevinedwards.rtls-web.created=$BUILD_DATE
LABEL com.kevinedwards.rtls-web.source=$SOURCE
LABEL com.kevinedwards.rtls-web.version=$VERSION
LABEL com.kevinedwards.rtls-web.vendor="Kevin Edwards"
LABEL com.kevinedwards.rtls-web.authors="Kevin Edwards <kedwards@kevinedwards.com"

# Update the system
RUN apk --no-cache -U upgrade

COPY --from=builder /app/build /usr/share/nginx/html
COPY nginx.conf.d /etc/nginx/conf.d

# Copy shell script to container
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
EOF

tee $(pwd)/jest.config.json <<'EOF' > /dev/null
{
  "verbose": true,
  "testEnvironment": "jsdom",
  "roots": [
    "<rootDir>/tests/",
    "<rootDir>/src/"
  ],
  "moduleFileExtensions": [
    "js",
    "jsx",
    "json"
  ],
  "collectCoverageFrom": [
    "<rootDir>/src/**/*.js",
    "!<rootDir>/src/index.js"
  ],
  "coverageReporters": [
    "text"
  ],
  "setupFilesAfterEnv": ["<rootDir>/tests/setupTests.js"]
}
EOF

# tee $(pwd)/package.json <<'EOF' > /dev/null
# {
#   "name": "ke-web",
#   "description": "KE-WEB",
#   "type": "module",
#   "repository": "https://github.com/kevinedwards/ke-web.git",
#   "author": "Kevin Edwards",
#   "license": "UNLICENSED",
#   "private": true,
#   "version": "0.0.0",
#   "scripts": {
#     "fmt": "prettier --write './src/**/*.{js,jsx}'",
#     "lint": "eslint './src/**/*.{js,jsx}'",
#     "lint:fix": "eslint --fix './src/**/*.{js,jsx}'",
#     "test": "jest --config jest.config.json",
#     "test:watch": "jest --watchAll",
#     "test:coverage": "jest --collect-coverage",
#     "start": "NODE_OPTIONS=--openssl-legacy-provider && webpack-dev-server --mode development --hot --open",
#     "build": "webpack --config webpack.config.js --mode production"
#   }
# }
# EOF

echo '# KE-WEB' > $(pwd)/README.md

# tee $(pwd)/webpack.config.js <<'EOF' > /dev/null
# import { fileURLToPath } from 'url';
# import path, { dirname } from 'path';
# import HtmlWebpackPlugin from 'html-webpack-plugin';

# const __dirname = dirname(fileURLToPath(import.meta.url));

# const config = {
#   entry: "./src/index.jsx",
#   output: {
#     filename: "bundle.[fullhash].js",
#     path: path.resolve(__dirname, "dist"),
#   },
#   devServer: {
#     port: 3000,
#   },
#   plugins: [
#     new HtmlWebpackPlugin({
#       template: "./public/index.html",
#     }),
#   ],
#   resolve: {
#     modules: [__dirname, "src", "node_modules"],
#     extensions: [".js", ".jsx"],
#   },
#   module: {
#     rules: [
#       {
#         test: /\.jsx?$/,
#         exclude: /node_modules/,
#         loader: 'babel-loader',
#       },
#       {
#         test: /\.css$/,
#         use: ["style-loader", "css-loader"],
#       },
#       {
#         test: /\.png|svg|jpg|gif$/,
#         use: ["file-loader"],
#       },
#     ],
#   },
# };

# export default config;
# EOF

# npm i @babel/runtime react react-dom react-router-dom > /dev/null

# npm i --save-dev webpack webpack-cli webpack-dev-server \
#   babel-loader @babel/preset-env @babel/core @babel/preset-react @babel/plugin-transform-runtime \
#   html-webpack-plugin css-loader style-loader file-loader \
#   prettier eslint-config-prettier eslint-plugin-prettier eslint eslint-plugin-jest eslint-config-airbnb eslint-plugin-import eslint-plugin-jsx-a11y eslint-plugin-react eslint-plugin-react-hooks \
#   prettier eslint-config-prettier eslint-plugin-prettier \
#   jest babel-jest react-test-renderer \
#   enzyme @wojtekmaj/enzyme-adapter-react-17 enzyme-to-json \
#   @testing-library/dom @testing-library/jest-dom @testing-library/react @testing-library/user-event > /dev/null

npm i --save-dev \
  prettier \
  eslint-config-prettier eslint-plugin-prettier \
  eslint eslint-plugin-jest eslint-config-airbnb eslint-plugin-import \
  eslint-plugin-jsx-a11y eslint-plugin-react eslint-plugin-react-hooks \
  @testing-library/jest-dom @testing-library/react @testing-library/user-event'