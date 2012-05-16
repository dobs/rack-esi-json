require 'thread'
#require 'timeout'

class Rack::ESI
  class Processor
    class Threaded < Processor
      THREAD_TIMEOUT = 10 # Thread execution timeout in seconds.

      # TODO Re-implement a queue system similar to boof implementation to
      # restrict current number of running threads.
      # TODO Better timeout implementation
      def process_document(document)
        threads = []
        document.split(Rack::ESI::Node::Tag::MATCH_TAG_REGEX).each do |fragment|
          threads << Thread.new { Thread.current[:body] = Node::Tag.new(esi, env, fragment).process }
        end
        threads.map { |thread| thread.join(THREAD_TIMEOUT)[:body] }.join('')
      end
    end
  end
end
