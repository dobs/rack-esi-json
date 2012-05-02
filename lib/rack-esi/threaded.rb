require 'thread'
#require 'timeout'

class Rack::ESI

  class Finisher < Proc
    def self.wait(queue)
      finisher = new do |worker|
        puts "Finishing #{ worker.inspect }..."
        worker[:finish] = true
        queue.push finisher
      end

      # cast the first stone
      queue.push finisher

      # wait at the end
      queue.pop
    end
  end

  class Worker < Thread
    def initialize(queue)
      super do
        begin
          queue.pop[ self ]
        rescue => e
          puts e
        end until key? :finish
      end
    end
  end

  class Processor::Threaded < Processor
    def process_document(document)
      # TODO Modify to run properly threaded -- likely won't work with current
      # gsub strategy
      countdown, main = document.scan(Rack::ESI::Node::Tag::MATCH_TAG_REGEX).length, Thread.current
      document.gsub(Rack::ESI::Node::Tag::MATCH_TAG_REGEX) do
        esi.queue do
          Node::Tag.new(esi, env, $1).process
          main.run if (countdown -= 1).zero?
        end
      end
      Thread.stop if countdown > 0 # wait for worker
    end
  end

end
