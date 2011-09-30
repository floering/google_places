module GooglePlaces
  class OverQueryLimitError < HTTParty::ResponseError
  end

  class RequestDeniedError < HTTParty::ResponseError
  end

  class InvalidRequestError < HTTParty::ResponseError
  end
end
