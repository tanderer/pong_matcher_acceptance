require "minitest/autorun"
require "json"
require "pp"

class PongMatcherAcceptance < Minitest::Test
  def setup
    @host = "http://localhost:3000"
    Admin.new(@host).clear
  end

  def test_that_lonely_player_cannot_be_matched
    @client = Client.new(@host, "williams")
    match_request = @client.request_match

    refute match_request.fulfilled?, "a single player shouldn't be matched"
  end

  def test_that_two_players_can_be_matched
    @client_1 = Client.new(@host, "williams")
    @client_2 = Client.new(@host, "sharapova")

    request_1 = @client_1.request_match
    request_2 = @client_2.request_match

    assert request_1.fulfilled?, "williams didn't receive notification of her match!"
    assert request_2.fulfilled?, "sharapova didn't receive notification of her match!"
  end
end

require "faraday"

class Admin
  def initialize(host)
    @http = Faraday.new(url: host)
  end

  def clear
    @http.delete("/all")
  end
end

class Client
  def initialize(host, id)
    @http = Faraday.new(url: host)
    @id = id
  end

  def request_match(match_request_id: SecureRandom.uuid)
    MatchRequest.new(match_request_id, http, id).tap(&:call)
  end

  private

  attr_reader :http, :id
end

require "securerandom"

class MatchRequest
  def initialize(id, http, player_id)
    @id = id
    @http = http
    @player_id = player_id
  end

  def call
    http.put(path, JSON.generate(player: player_id))
  end

  def fulfilled?(debug = false)
    response = get(path)
    pp JSON.parse(response.body) if debug && response.status == 404
    response.status == 200 && has_match_id?(response)
  end

  private

  def get(path)
    http.get(path).tap do |response|
      if response.status >= 400 && response.status != 404
        raise "invalid response received: #{response.status}"
      end
    end
  end

  def match_id_from_response(response)
    extract(response, "match_id")
  end

  def extract(response, attribute)
    JSON.parse(response.body)[attribute]
  end

  def has_match_id?(response)
    match_id = match_id_from_response(response)
    match_id != "" && !match_id.nil?
  end

  def path
    "/match_requests/#{id}"
  end

  attr_reader :id, :http, :player_id
end
