require "minitest/autorun"
require "json"

class PongMatcherAcceptance < Minitest::Test
  def setup
    host = ENV.fetch("HOST", "http://localhost:3000")
    @client = Client.new(host)
    @client.delete('/all')
  end

  attr_reader :client

  def test_that_getting_a_bogus_match_request_404s
    response = client.get('/match_requests/completelymadeup')
    assert_equal 404, response.status
  end

  def test_that_lonely_player_cannot_be_matched
    put_response = client.put('/match_requests/lonesome', 'player' => 'some-player')
    assert_equal 200, put_response.status

    get_response = client.get('/match_requests/lonesome')
    assert_equal 200, get_response.status

    expected_representation = { 'id' => 'lonesome',
                                'player' => 'some-player',
                                'match_id' => nil }
    assert_equal(expected_representation, JSON.parse(get_response.body))
  end

  def test_that_two_players_can_be_matched
    client.put('/match_requests/williams1', 'player' => 'williams')
    client.put('/match_requests/sharapova1', 'player' => 'sharapova')

    williams_match_id, response_1 = get_match_id('williams1')
    sharapova_match_id, response_2 = get_match_id('sharapova1')

    assert williams_match_id,
      ["Williams didn't receive notification of her match!",
       response_1.body].join("\n")
    assert sharapova_match_id,
      ["Sharapova didn't receive notification of her match!",
       response_2.body].join("\n")

    request_ids = get_match_request_ids(williams_match_id)

    assert_includes request_ids, 'sharapova1',
      "Couldn't retrieve the opponent request ID for Williams' request!"
    assert_includes request_ids, 'williams1',
      "Couldn't retrieve the opponent request ID for Sharapova's request!"
  end

  def test_that_entering_result_ensures_match_with_new_player
    client.put('/match_requests/williams1', 'player' => 'williams')
    client.put('/match_requests/sharapova1', 'player' => 'sharapova')

    match_id, _ = get_match_id('williams1')
    request_ids = get_match_request_ids(match_id)

    assert_equal %w(williams1 sharapova1).sort, request_ids.sort

    response = client.post('/results',
                           'match_id' => match_id,
                           'winner' => 'sharapova',
                           'loser' => 'williams')
    assert_equal 201, response.status

    client.put('/match_requests/williams2', 'player' => 'williams')
    client.put('/match_requests/sharapova2', 'player' => 'sharapova')
    client.put('/match_requests/navratilova1', 'player' => 'navratilova')

    new_match_id, new_response = get_match_id('williams2')
    assert new_match_id,
      "Williams didn't receive notification of her match! #{new_response.body}"

    request_ids = get_match_request_ids(new_match_id)
    refute_includes request_ids, 'sharapova2',
      "Expected Williams to be matched with Navratilova, but Sharapova got Navratilova (ordering issue)"

    sharapova_match_id, sharapova_response = get_match_id('sharapova2')
    refute sharapova_match_id,
      ["Sharapova shouldn't have a match, because she just played Williams!",
       "Expected Navratilova to be matched with Williams.",
       request_ids,
       sharapova_response.body].join("\n")

    navratilova_match_id, navratilova_response = get_match_id('navratilova1')
    assert navratilova_match_id,
      "Navratilova didn't receive notification of her match!"
  end

  def get_match_request_ids(match_id)
    match = JSON.parse(client.get("/matches/#{match_id}").body)
    match.values_at('match_request_1_id', 'match_request_2_id')
  end

  def get_match_id(match_request_id)
    response = client.get("/match_requests/#{match_request_id}")
    [JSON.parse(response.body)['match_id'], response]
  end
end

require "faraday"

class Client
  attr_reader :id

  def initialize(host)
    @http = Faraday.new(url: host,
                        headers: {"Content-Type" => "application/json",
                                  "Accept" => "application/json"})
  end

  def delete(path)
    http.delete(path)
  end

  def get(path)
    http.get(path)
  end

  def put(path, body)
    http.put(path, JSON.generate(body))
  end

  def post(path, body)
    http.post(path, JSON.generate(body))
  end

  private

  attr_reader :http
end
