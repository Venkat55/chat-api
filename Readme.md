# chat-api

chat-api is a Ruby application with Sinatra framework which would enable a web app to build a simple messenger application.

## Environment Prerequisites
### Ruby version: 2.6.3p62
### Mongodb version(community): 5.0.3

## Mongodb Installation on Mac
[Official Documentation](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-os-x/)

```bash
brew tap mongodb/brew
brew install mongodb-community@5.0
brew services start mongodb/brew/mongodb-community
```

## Installation

```bash
git clone https://github.com/Venkat55/chat-api.git
gem install bundler
bundle install
```

## To start the server

```bash
# starts the server in default port 4567
bundle exec ruby app.rb 
```

## API Documentation
API Documentation for this app can be found in this [link](https://documenter.getpostman.com/view/13363258/UV5Uiy6X)
