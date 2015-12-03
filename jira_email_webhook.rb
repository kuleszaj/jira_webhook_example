# encoding: utf-8
require 'sinatra'
require 'rack/ssl'
require 'logger'
require 'json'
require 'mail'
require 'RedCloth'
require 'erb'

# JiraEmailWebhook
class JiraEmailWebhook < Sinatra::Application
  ::Logger.class_eval { alias_method :write, :'<<' }

  enable :sessions

  set :session_secret, 'e92be1f10ad3cd7bc17233ab48f7819e4c29bd0fea0ff1e1f48a4f'\
                       '547c58cede'

  set :smtp_server, ENV['SMTP_SERVER']
  set :smtp_port, ENV['SMTP_PORT']
  set :smtp_domain, ENV['SMTP_DOMAIN']
  set :smtp_username, ENV['SMTP_USERNAME']
  set :smtp_password, ENV['SMTP_PASSWORD']

  configure :production do
    app_logger = ::Logger.new(STDOUT)
    set :logging, ::Logger::WARN
    use ::Rack::CommonLogger, app_logger
    use ::Rack::SSL
    set :mail_delivery_method, :smtp
    set :dump_errors, false
    set :raise_errors, false
  end

  configure :development do
    app_logger = ::Logger.new(STDOUT)
    set :logging, ::Logger::DEBUG
    use ::Rack::CommonLogger, app_logger
    set :mail_delivery_method, :test
  end

  configure :test do
    app_logger = ::Logger.new(STDOUT)
    set :logging, ::Logger::INFO
    use ::Rack::CommonLogger, app_logger
    set :mail_delivery_method, :test
  end

  before do
    env['rack.errors'] = STDOUT
  end

  post '/emailupdate' do
    request.body.rewind

    json = JSON.parse(request.body.read)

    logger.debug(json)

    @issue = json['issue']['key']
    @submitter = json['issue']['fields']['customfield_10100']
    @title = json['issue']['fields']['summary']
    @description = json['issue']['fields']['description']
    @old_status = json['transition']['from_status']
    @new_status = json['transition']['to_status']
    @comment = json['comment']

    plain_email = erb :card_update_plain
    html_email = erb :card_update_html

    mail = Mail.new do
      text_part do
        body plain_email
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body html_email
      end
    end

    mail.from = 'Support Team <support@example.com>'
    mail.to = "#{@submitter} <#{@submitter}@example.com>"
    mail.subject = "#{@issue} (#{@title}) now has a status of: #{@new_status}"

    mail.delivery_method settings.mail_delivery_method,
                         address: settings.smtp_server,
                         port: settings.smtp_port,
                         domain: settings.smtp_port,
                         user_name: settings.smtp_username,
                         password: settings.smtp_password,
                         authentication: 'plain',
                         enable_starttls_auto: true

    logger.debug(mail.inspect)
    logger.info("Sending mail to: #{mail.to}, with subject: #{mail.subject}")

    begin
      mail.deliver!
    rescue StandardError => ex
      logger.error(ex.class)
      logger.error('Something went wrong when sending the e-mail!')
      logger.error(ex)
      halt 500
    end
  end
end

# Helper for formatting text
module Formatter
  def convert_jira_issue_for_email(text)
    html = RedCloth.new(text).to_html
    html.gsub!("\r\n", "\n")
    html.gsub!(/({code})((.*\n)*?)({code})/, '<code>\2</code>')
    html.gsub!('{{', '<code>')
    html.gsub!('}}', '</code>')
    html
  end
end

JiraEmailWebhook.helpers Formatter
