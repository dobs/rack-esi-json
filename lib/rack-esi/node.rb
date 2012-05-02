class Rack::ESI
  class Node < Struct.new(:esi, :env, :data)
    class Tag < self
      attr_reader :name, :attributes

      ON_ERROR_CONTINUE = 'continue'

      IncludeError = Class.new RuntimeError

      def initialize(esi, env, data)
        super(esi, env, data)
        parse(data)
      end

      def include(path)
        esi.call env.merge('PATH_INFO' => path, 'REQUEST_URI' => path)
      rescue => e
        return 500, {}, []
      end

      def process
        case self.name
        when 'include'
          status, headers, body = include self.attributes['src']

          unless status == 200 or self.attributes['alt'].nil?
            status, headers, body = include self.attributes['alt']
          end

          if status == 200
            self.replace read(body)
          elsif self.attributes['onerror'] != ON_ERROR_CONTINUE
            raise IncludeError
          end
        end
      end

      protected

      def parse
        # TODO Parse tag attributes
      end
    end

    def process
      raise NotImplementedError
    end
  end
end
