module GooglePlaces
  class Request
    attr_accessor :response

    include ::HTTParty
    format :json

    SPOTS_LIST_URL = 'https://maps.googleapis.com/maps/api/place/search/json'
    SPOT_URL = 'https://maps.googleapis.com/maps/api/place/details/json'

    def self.spots(options = {})
      request = new(SPOTS_LIST_URL, options)
      request.parsed_response
    end

    def self.spot(options = {})
      request = new(SPOT_URL, options)
      request.parsed_response
    end

    def initialize(url, options)
      retry_options = options.delete(:retry_options) || {}

      retry_options[:status]  ||= []
      retry_options[:timeout] ||= 20.second
      retry_options[:delay]   ||= 5.second
      retry_options[:max]     ||= 3

      retry_options[:status] = [retry_options[:status]] unless retry_options[:status].is_a?(Array)

      @response = self.class.get(url, :query => options)

      begin
        Timeout::timeout(timeout) {
          while retry_options[:max] > 0 && retry_options[:status].include?(@response.parsed_response['status'])
            sleep(retry_options[:delay])
            @response = self.class.get(url, :query => options)
            retry_options[:max] -= 1
          end
        }
      rescue Timeout::Error
      end
    end

    def parsed_response
      case @response.parsed_response['status']
      when 'OK', 'ZERO_RESULTS'
        @response.parsed_response
      when 'OVER_QUERY_LIMIT'
        raise OverQueryLimitError.new(@response)
      when 'REQUEST_DENIED'
        raise RequestDeniedError.new(@response)
      when 'INVALID_REQUEST'
        raise InvalidRequestError.new(@response)
      end
    end
  end
end
