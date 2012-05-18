require 'rack'
require 'bundler'
Bundler.require

require File.expand_path('../rack-esi/processor', __FILE__)
require File.expand_path('../rack-esi/node', __FILE__)

class Rack::ESI
  attr_accessor :timeout

  def initialize(app, options = {})
    @app         = app
    @conditional = options.fetch :if, ->(env){ true }
    @serializer  = options.fetch :serializer, :to_s
    @skip        = options[:skip]
    @poolsize    = options.fetch :poolsize, 4
    @processor   = @poolsize == 1 ? Processor::Linear : Processor::Threaded
    @timeout     = options.fetch :timeout, 300
  end

  def read(enumerable, buffer = '')
    enumerable.each { |str| buffer << str }
    buffer
  end

  attr_reader :serializer

  def call(env)
    return @app.call(env) if @skip === env['PATH_INFO']

    status, headers, body = @app.call env.dup

    if status == 200 && @conditional.call(env.dup)
      body = @processor.new(self, env).process body
    end

    return status, headers, body
  end
end
