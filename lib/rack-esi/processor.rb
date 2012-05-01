class Rack::ESI
  class Processor < Struct.new(:esi, :env)
    class Linear < self
      def process_document(d)
        d.gsub(Rack::ESI::Tag::MATCH_TAG_REGEX) do
          Node::Tag.new(esi, env, $1).process
        end
      end
    end

    autoload :Threaded, File.expand_path('../threaded', __FILE__)

    Error = Class.new RuntimeError

    def read(enumerable, buffer = '')
      enumerable.each { |str| buffer << str }
      buffer
    end

    def process_node(node)
    end

    def process_document(document)
      raise NotImplementedError
    end

    def process(body)
      document = read(body)
      process_document document
      [
        document.send( esi.serializer )
      ]
    end
  end
end
