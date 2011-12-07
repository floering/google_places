require 'open-uri'

module GooglePlaces
  class Spot
    attr_accessor :reference

    def self.list(lat, lng, api_key, options = {})
      radius        = options.delete(:radius)        || 200
      sensor        = options.delete(:sensor)        || false
      types         = options.delete(:types)
      name          = options.delete(:name)
      language      = options.delete(:language)
      location      = Location.new(lat, lng)
      exclude       = options.delete(:exclude)       || []
      retry_options = options.delete(:retry_options) || {}

      exclude = [exclude] unless exclude.is_a?(Array)

      options = {
        :location      => location.format,
        :radius        => radius,
        :sensor        => sensor,
        :key           => api_key,
        :name          => name,
        :language      => language,
        :retry_options => retry_options
      }

      # Accept Types as a string or array
      if types
        types = (types.is_a?(Array) ? types.join('|') : types)
        options.merge!(:types => types)
      end

      response = Request.spots(options)
      response['results'].map do |result|
        self.new(result, sensor, api_key, language, retry_options) if (result['types'] & exclude) == []
      end.compact
    end

    def self.find(reference, api_key, options = {})
      sensor        = options.delete(:sensor)        || false
      language      = options.delete(:language)
      retry_options = options.delete(:retry_options) || {}

      response = Request.spot(
        :reference     => reference,
        :sensor        => sensor,
        :key           => api_key,
        :language      => language,
        :retry_options => retry_options
      )

      self.new(response['result'], sensor, api_key, language, retry_options) if response['status'] == 'OK'
    end

    def initialize(json_result_object, sensor, api_key, language, retry_options = {})
      set_class_vars(json_result_object)
      @sensor        = sensor
      @api_key       = api_key
      @language      = language
      @retry_options = retry_options
    end
    
    def set_class_vars(json_result_object)
      @reference              = json_result_object['reference']
      @vicinity               = json_result_object['vicinity']
      @lat                    = json_result_object['geometry']['location']['lat']
      @lng                    = json_result_object['geometry']['location']['lng']
      @name                   = json_result_object['name']
      @icon                   = json_result_object['icon']
      @types                  = json_result_object['types']
      @id                     = json_result_object['id']
      @formatted_phone_number = json_result_object['formatted_phone_number']
      @formatted_address      = json_result_object['formatted_address']
      @address_components     = json_result_object['address_components']
      @rating                 = json_result_object['rating']
      @url                    = json_result_object['url']
    end
    
    def refresh
      response = Request.spot(
        :reference     => @reference,
        :sensor        => @sensor,
        :key           => @api_key,
        :language      => @language,
        :retry_options => @retry_options
      )
      
      if response['status'] == 'OK'
        set_class_vars(response['result'])
        @refreshed = true
      end
    end
    
    def closed?
      web_url = self.url
      if @closed.nil?
        @closed = open(web_url).read.include?('place is permanently closed')
      end
      @closed
    end 
    
    ['lat', 'lng', 'vicinity', 'name', 'icon', 'types', 'id', 'formatted_phone_number', 'formatted_address', 'address_components', 'rating', 'url'].each do |local_method|
      class_eval %Q&
        def #{local_method}
          if @#{local_method}.nil? and !@refreshed
            refresh
          end
          @#{local_method}
        end
      &
    end

  end
end
