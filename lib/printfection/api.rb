module Printfection
  module API
    ENDPOINT = "api.printfection.com/v2/"

    attr_accessor :api_token
    attr_accessor :logger

    def get(uri="/", params={})
      request :get, uri, params
    end

    def post(uri, data={})
      request :post, uri, data
    end

    def patch(uri, data={})
      request :patch, uri, data
    end

    def delete(uri)
      request :delete, uri
    end

    def request(verb, uri, params={})
      perform_request do
        uri = Util.join_uri(ENDPOINT, uri)
        url = "https://#{api_token}:@#{uri}"

        unless logger.nil?
          logger.info "[Printfection] #{verb.upcase} #{url}"
        end

        response = case verb
        when :get;    RestClient.get url, :params => params, :accept => :json
        when :post;   RestClient.post url, params.to_json, :accept => :json, :content_type => :json
        when :patch;  RestClient.patch url, params.to_json, :accept => :json, :content_type => :json
        when :delete; RestClient.delete url
        end

        json = JSON.parse(response.body)

        if json["object"] == "list" and json.has_key? "data"
          json["data"]
        else
          json
        end
      end
    end

    private

    def perform_request(&block)
      begin
        yield

        # At this point, some exception has been raised either
        # during the request or parsing the response.
        #
        # We determine the type of error, and re-raise
        # our own error from the message in the response body.
      rescue RestClient::Exception => e
        # We likely got a http status code outside the 200-399 range.
        # If this is a GET or DELETE request, it is likely the resource is not owned by the client.
        # If this is a POST, PUT, or PATCH, the data might be invalid.

        # Handle 400, 401, and 404 errors.
        # 400 Bad Request  - Invalid or missing request parameters.
        # 401 Unauthorized - Invalid API key provided.
        # 404 Not Found    - The requested item doesn't exist or the client doesn't own it.
        if [400, 401, 404].include?(e.http_code)
          raise Error, JSON.parse(e.http_body)["message"]
        end

        # Handle any other http error (i.e. 5xx+), or other RestClient exceptions.
        # Re-raise a generic error.
        raise Error, "Something went wrong with the request. Please try again."
      rescue JSON::ParserError => e
        # We received the data fine, but we're unable to parse it.
        # Re-raise a generic error.
        raise Error, "Something went wrong parsing the response. Please try again."
      rescue StandardError => e
        # Something else went wrong.
        # Re-raise a generic error.
        raise Error, "Something went wrong. Please try again."
      end
    end

  end
end

