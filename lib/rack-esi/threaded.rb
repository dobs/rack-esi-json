require 'thread'
#require 'timeout'

class Rack::ESI
  class Processor
    class Threaded < Processor
      # TODO Re-implement a queue system similar to boof implementation to
      # restrict current number of running threads.
      # TODO Better timeout implementation
      def process_document(document)
        threads = []
        document.split(Rack::ESI::Node::Tag::MATCH_TAG_REGEX).each do |fragment|
          threads << Thread.new do
            Thread.current[:body] = Node::Tag.new(esi, env, fragment).process
          end
        end
        threads.map do |thread|
          thread[:body] if thread.join(esi.timeout)
        end.compact.join('')
      end
    end
  end
end
