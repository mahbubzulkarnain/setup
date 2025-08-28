#!/usr/bin/env bash

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if ! [ -s "$NVM_DIR/nvm.sh" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    fi
    if ! command -v npm &>/dev/null; then
        nvm install --lts

        echo "Install Global node_modules"
        npm i -g node-gyp nodemon pm2 live-server
        # npm i -g serverless
        # npm i -g aws-sam-local

        #npm i -g http-server
        #npm i -g json-server
        #npm i -g localtunnel

        # Database
        # npm i -g sequelize-cli

        # Debugging
        npm i -g ndb
        npm i -g node-inspector

        # Firebase
        # npm i -g firebase-tools

        # Generator
        # npm i -g @angular/cli
        # npm i -g @vue/cli
        # npm i -g express-generator
        # npm i -g create-react-app
        # npm i -g create-react-library
        # npm i -g create-react-native-app
        # npm i -g react-native-cli
        # npm i -g exp
        # npm i -g expo-cli

        # Linting
        npm i -g eslint
        npm i -g standard
        npm i -g typescript
        npm i -g tslint
        #npm i -g babel-eslint
        #npm i -g eslint-config-standard
        #npm i -g eslint-config-standard-react
        #npm i -g eslint-config-standard-jsx
        #npm i -g eslint-plugin-react
        #npm i -g eslint-config-prettier
        #npm i -g eslint-plugin-prettier
        #npm i -g prettier

        # Test
        npm i -g mocha
        npm i -g jest

        # Utilities
        npm i -g now
        #npm i -g branch-diff
        #npm i -g tldr
        #npm i -g spoof
        #npm i -g fkill-cli
        #npm i -g castnow
        #npm i -g github-is-starred-cli
        #npm i -g vtop

        #david - Find Out When Your Dependencies are Outdated
        #npm i -g david

        # Working with npm
        npm i -g yarn
        #npm i -g npx
        #npm i -g np
        #npm i -g npm-name-cli

        echo "Check list global node_modules..."
        npm list -g --depth 0

    fi
fi
