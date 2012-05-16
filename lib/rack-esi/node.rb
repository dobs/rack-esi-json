class Rack::ESI
  class Node < Struct.new(:esi, :env, :data)
    class Tag < self
      attr_reader :namespace, :name, :attributes

      ON_ERROR_CONTINUE = 'continue'
      MATCH_TAG_REGEX = /(\<esi\:.*?\/\>)/
      PARSE_TAG_REGEX = /\<(?:(?<namespace>\w+):)?(?<name>\w+)(?<attributes>\s+.*?)\s*\/?\>/
      PARSE_ATTRIBUTES_REGEX = /\s+(?<key>\w+)=['"](?<value>.*?)['"]/

      IncludeError = Class.new RuntimeError

      def initialize(esi, env, data)
        super(esi, env, data)
      end

      def include(path)
        path_info, query_string = path.split '?'
        esi.call env.merge('PATH_INFO' => path_info, 'REQUEST_URI' => path, 'QUERY_STRING' => query_string)
      rescue => e
        return 500, {}, []
      end

      def process
        parse(data)
        case name
        when 'include'
          status, headers, body = include self.attributes['src']

          unless status == 200 or self.attributes['alt'].nil?
            status, headers, body = include self.attributes['alt']
          end

          if status == 200
            esi.read(body)
          elsif self.attributes['onerror'] != ON_ERROR_CONTINUE
            raise IncludeError
          end
        end
      rescue
        data
      end

      protected

      def parse(data)
        @namespace, @name, attrs = PARSE_TAG_REGEX.match(data).captures

        @attributes = {}
        if !attrs.nil?
          attrs.scan(PARSE_ATTRIBUTES_REGEX).each do |key, value|
            @attributes[key] = value
          end
        end
      end
    end

    def process
      raise NotImplementedError
    end
  end
end
