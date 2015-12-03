# Jira Webhook Example

This repository contains a simple web application which is designed to accept a JSON blob from a JIRA callback.

The data is parsed, and an e-mail message is constructed for delivery.

This application was designed to run on Heroku, and support custom fields in JIRA. A sample JSON file containing data to test the application is included.

## Getting Started

- `bundle install`
- `bundle exec rake app:run`

## POST'ing sample data to the app

- `curl -i -X POST --data @sample_data.json http://localhost:9292/emailupdate`

## Environment Variables for Production Usage

- `SMTP_SERVER` - SMTP server hostname. e.g. `smtp.example.com`
- `SMTP_PORT` - SMTP server port for TLS. e.g. `587`
- `SMTP_DOMAIN` - SMTP e-mail domain. e.g. `example.com`
- `SMTP_USERNAME` - SMTP username. e.g. `justin@example.com`
- `SMTP_PASSWORD` - SMTP password. e.g. `abc123secret`
