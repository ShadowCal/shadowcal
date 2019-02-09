# frozen_string_literal: true

# Google Calendar API tries to use an old cypher?
# https://stackoverflow.com/questions/33572956/ruby-ssl-connect-syscall-returned-5-errno-0-state-unknown-state-opensslssl
# OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ciphers] += ":DES-CBC3-SHA"
# OpenSSL::SSL::SSLContext::DEFAULT_PARAMS[:ssl_version] = :TLSv1

# require 'net/http'
# require 'openssl'

# unless Rails.env.production?
#   class Net::HTTP   alias_method :origConnect, :connect
#     def connect
#       @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
#       origConnect
#     end
#   end
# end
