# SalesforceAPI

Salesforce project exposing an API interface for an external chatbot.

## Prerequisites

- Node.js
- Salesforce CLI (`npm install -g @salesforce/cli`)
- Git

## Getting started

    git clone https://github.com/mido8989/SalesforceAPI.git
    cd SalesforceAPI
    sf org login web --alias playground --set-default

## Manual setup: External Client App

The app is created by hand in each org and is not stored in this repository.

1. Setup > External Client App Manager > New External Client App
2. Name: `Chatbot API`, Distribution State: Local
3. Enable OAuth, Callback URL: `http://localhost:1717/OauthRedirect`
4. OAuth Scopes: Manage user data via APIs (api)
5. Flow Enablement: Enable Client Credentials Flow
6. After creating: Policies > Edit > OAuth Policies > Enable Client
   Credentials Flow, and set Run As (Username) to the integration user

The consumer key and secret are per org. Never commit them.

## Workflow

`main` is only changed through pull requests. For each piece of work:

    git switch main
    git pull
    git switch -c feature/short-description

Commit, push the branch, open a pull request, merge, then delete the branch.