require 'rack'
require 'bundler'
Bundler.require

require File.expand_path('../rack-esi/processor', __FILE__)
require File.expand_path('../rack-esi/node', __FILE__)

class Rack::ESI

  def initialize(app, options = {})
    @app        = app

    @serializer = options.fetch :serializer, :to_s
    @skip       = options[:skip]
    @poolsize   = options.fetch :poolsize, 4
    @processor  = @poolsize == 1 ? Processor::Linear : Processor::Threaded
  end

  def queue(&block)
    unless @queue
      @queue, @group = Queue.new, ThreadGroup.new
      @poolsize.times { @group.add Worker.new(@queue) }

      at_exit { Finisher.wait @queue }
    end

    @queue.push block
  end

  attr_reader :serializer

  def call(env)
    return @app.call(env) if @skip === env['PATH_INFO']

    status, headers, body = @app.call env.dup

    if status == 200
      body = @processor.new(self, env).process body
    end

    return status, headers, body
  end

end
