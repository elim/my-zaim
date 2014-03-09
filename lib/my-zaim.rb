require 'bundler/setup'
require 'oauth'
require 'oauth/consumer'
require 'open-uri'
require 'yaml'

require 'pry'

class MyZaim
  def initialize
    consumer = load_consumer_setting
    @consumer = OAuth::Consumer.new(
      consumer[:consumer_key],
      consumer[:consumer_secret],
      site:               'https://api.zaim.net',
      request_token_path: 'https://api.zaim.net/v2/auth/request',
      authorize_path:     'https://auth.zaim.net/users/auth',
      access_token_path:  'https://api.zaim.net/v2/auth/access'
    )

    @access_token = get_access_token
    binding.pry
  end

  private

  def get_access_token
    return load_access_token if has_access_yml?

    request_token = get_request_token
    verifier = gets_verifer(request_token.authorize_url)

    access_token = request_token.get_access_token(
      oauth_verifier: verifier
    )

    access_info = {
      token:  access_token.token,
      secret: access_token.secret
    }

    open(access_yaml, 'w') do |f|
      f.puts access_info.to_yaml
    end

    access_token
  end

  def load_consumer_setting
    YAML.load_file(consumer_yaml)
  end

  def load_access_token
    auth = YAML.load_file(access_yaml)

    OAuth::AccessToken.new(@consumer, auth[:token], auth[:secret])
  end

  def has_access_yml?
    File.exist?(access_yaml)
  end

  def consumer_yaml
    File.expand_path('consumer.yml', config_dir)
  end

  def access_yaml
    File.expand_path('access.yml', config_dir)
  end

  def config_dir
    dir = File.dirname(__FILE__) + '/../config'
    File.expand_path(dir)
  end

  def gets_verifer(authorize_url)
    print <<-"EOF"
      1: Plese open #{authorize_url} .
      2: Login to Zaim If neccesary.
      3: Show HTML souce and search <code> element.
      3: Finally, paste that verifier.
    EOF
    print 'verifier: '

    gets.chomp
  end

  def get_request_token
    request_token = @consumer.get_request_token(
      oauth_callback: 'http://example.com/pseudo_callback'
    )
  end
end
