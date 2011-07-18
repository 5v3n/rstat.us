  configure :test do
    PONY_VIA_OPTIONS = {}
  end

  configure :development do
    PONY_VIA_OPTIONS = {}
  end

  # We're using [SendGrid](http://sendgrid.com/) to send our emails. It's really
  # easy; the Heroku addon sets us up with environment variables with all of the
  # configuration options that we need.
  configure :production do
    PONY_VIA_OPTIONS =  {
      :address        => "smtp.sendgrid.net",
      :port           => "25",
      :authentication => :plain,
      :user_name      => ENV['SENDGRID_USERNAME'],
      :password       => ENV['SENDGRID_PASSWORD'],
      :domain         => ENV['SENDGRID_DOMAIN']
    }
  end

  # We need a secret for our sessions. This is set via an environment variable so
  # that we don't have to give it away in the source code. Heroku makes it really
  # easy to keep environment variables set up, so this ends up being pretty nice.
  # This also has to be included before rack-flash, or it blows up.
  use Rstatus::Session, :secret => ENV['COOKIE_SECRET']

  # We're using rack-timeout to ensure that our dynos don't get starved by renegade
  # processes.
  use Rack::Timeout
  Rack::Timeout.timeout = 10

  set :root, File.join(File.dirname(__FILE__), "..")
  set :haml, :escape_html => true
  set :logging, true

  # This method enables the ability for our forms to use the _method hack for
  # actual RESTful stuff.
  set :method_override, true

  # If you've used Rails' flash messages, you know how convenient they are.
  # rack-flash lets us use them.
  use Rack::Flash

  # Tilt likes it when things are explicitly required.
  require "coffee-script"

  configure do

    Compass.add_project_configuration(File.join(File.dirname(__FILE__), 'compass.config'))
    MongoMapperExt.init

    # now that we've connected to the db, let's load our models.
    require_relative '../models/all'
  end

  helpers Sinatra::UserHelper
  helpers Sinatra::ViewHelper
  helpers Sinatra::ContentFor

  helpers do
    [:development, :production, :test].each do |environment|
      define_method "#{environment.to_s}?" do
        return settings.environment == environment
      end
    end
  end
end
