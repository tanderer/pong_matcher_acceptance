require "minitest/autorun"
require "json"

class PongMatcherAcceptance < Minitest::Test
  def setup
    @host = "http://localhost:3000"
    Admin.new(@host).clear
  end

  def test_that_lonely_player_cannot_be_matched
    @williams = Client.new(@host, "williams")
    match_request = @williams.request_match

    refute match_request.fulfilled?, "a single player shouldn't be matched"
  end

  def test_that_two_players_can_be_matched
    @williams = Client.new(@host, "williams")
    @sharapova = Client.new(@host, "sharapova")

    request_1 = @williams.request_match
    request_2 = @sharapova.request_match

    assert request_1.fulfilled?, "williams didn't receive notification of her match!"
    assert request_2.fulfilled?, "sharapova didn't receive notification of her match!"
  end

  def test_that_entering_result_ensures_match_with_new_player
    @williams = Client.new(@host, "williams")
    @sharapova = Client.new(@host, "sharapova")
    @navratilova = Client.new(@host, "navratilova")

    williams_request_id = SecureRandom.uuid

    williams_request = @williams.request_match(match_request_id: williams_request_id)
    @sharapova.request_match

    @williams.loses_to(@sharapova, match_id: williams_request.match_id)

    williams_new_request = @williams.request_match
    sharapova_new_request = @sharapova.request_match
    navratilova_request = @navratilova.request_match

    assert williams_new_request.fulfilled?,
      "Williams didn't receive notification of her match!"

    refute sharapova_new_request.fulfilled?,
      "Sharapova just played Williams! Expected Navratilova to be matched with Williams."

    assert navratilova_request.fulfilled?,
      "Navratilova didn't receive notification of her match!"
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
  attr_reader :id

  def initialize(host, id)
    @http = Faraday.new(url: host)
    @id = id
  end

  def request_match(match_request_id: SecureRandom.uuid)
    MatchRequest.new(match_request_id, http, id).tap(&:call)
  end

  def loses_to(winner, options)
    enter_result(
      match_id: options.fetch(:match_id),
      winner: winner,
      loser: self
    )
  end

  private

  def enter_result(match_id: nil, winner: nil, loser: nil)
    if [match_id, winner].any?(&:nil?)
      raise ArgumentError, "One of match_id: #{match_id}, winner: #{winner} is nil!"
    else
      http.post("/results", JSON.generate(match_id: match_id, winner: winner.id, loser: loser.id))
    end
  end

  attr_reader :http
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

  def fulfilled?
    response = get(path)
    response.status == 200 && has_match_id?(response)
  end

  def match_id
    response = get(path)
    extract(response, "match_id")
  end

  private

  def get(path)
    http.get(path).tap do |response|
      if response.status >= 400 && response.status != 404
        raise "invalid response received: #{response.status}"
      end
    end
  end

  def extract(response, attribute)
    JSON.parse(response.body)[attribute]
  end

  def has_match_id?(response)
    match_id = extract(response, "match_id")
    match_id != "" && !match_id.nil?
  end

  def path
    "/match_requests/#{id}"
  end

  attr_reader :id, :http, :player_id
end
