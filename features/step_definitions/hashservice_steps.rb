require 'httparty'
require 'minitest'

Given(/^the service is running$/) do
  if !check_service
    start_service
    up = check_service
  end

end

Then(/^the service status is (true|false)$/) do |status|
  assert check_service==to_boolean(status), "Expected service status of #{status}"
end

When(/^I shutdown the service$/) do
  stop_service
end

When(/^I request the service stats with id (.+)$/) do |id|
  $bridge['stats'][id] = service_getstats
  assert $bridge['stats'][id].code==200, "Stats request returned #{$bridge['stats'][id].code}"
end

And(/^the stats with id (.+) should match the expected stats/) do |id|
  #eventually I'd like to extend this to include matching an arbitrary stats object, but for now only use the
  #stats we keep internally of how many requests we've made

  body = JSON.parse($bridge['stats'][id].body)
  assert body['TotalRequests'].to_i == $bridge['internal']['count'], "Total request count does not match expected, actual=#{body['TotalRequests'].to_i}, expected = #{$bridge['internal']['count']}"
  assert body['AverageTime'].to_i >=0, "Average time doesn't make sense #{body['AverageTime'].to_i}"

  puts body
end

When(/^I submit a job for password \[(.*)\] with id (.*)/) do |password, id|
  submit_job(id, password)
end

Then(/^the job response for (.+) should be valid$/) do |id|
  response = $bridge['jobs'][id]['response']
  assert response.code == 200, "Unexpected response submitting a job #{response.code}"

  #undone might be better to add check here that the jobid is valid (is it always a number, the spec doesn't say?)
  # but the truth is the second step where we request the hash value would catch invalid jobids as well
end

When(/^I wait (\d+) seconds$/) do |wait|
  sleep wait.to_i
end

And(/^request the hash value for id (.+) and save it with id (.+)$/) do |id, newid|
  get_hash(id, newid)
end

Then(/^the hash for job (.+) and response (.+) should match$/) do |id, newid|
  expected = Base64.strict_encode64(Digest::SHA2.new(512).digest($bridge['jobs'][id]['password']))
  actual = $bridge['hashes'][newid].body

  assert (expected==actual), "HASH not correct! expected=#{expected}, actual=#{actual}"
end

When(/^I submit a job with an invalid body with id (.+)$/) do |id|
  body = {"bogus" => "angrymonkey"}
  $response=HTTParty.post "#{$props['service_base_url']}/hash", :body=>body.to_json
end

Then(/^the last response should be (\d+)$/) do |code|
  assert $response.code == code.to_i, "HTTP status code is not expected value expected=#{code}, actual=#{$response.code}"
  if !($response.code == 200)
    #undone: if the spec included what error messages were returned, it would be better to assert on the message
    #directly
    puts "Error message returned, does it seem reasonable? #{$response.body}"
  end
end

When(/^I request a hash value with extra keys in payload with id (.+)$/) do |id|
  body = {"password" => "angrymonkey", "bogus": "somethingelse"}
  $response=HTTParty.post "#{$props['service_base_url']}/hash", :body=>body.to_json
  $bridge['jobs'][id] = {"password" => "angrymonkey", "response" => $response}
end

When(/^I submit a job with a random password of length (\d+) with id (.+)/) do |length, id|
  password = random_str(length.to_i)
  puts "Generated random password #{password}"
  submit_job(id,password)
end

When(/^I submit a job with a special character password with the id (.+)/) do |id|
  password = "\"{}\\[]:=\'"

  submit_job(id, password)
end

When(/^I request the hash value without a jobid$/) do
  $response = HTTParty.get("#{$props['service_base_url']}/hash/")
end

When(/^I request the hash value for a jobid (.*)$/) do |jobid|
  $response = HTTParty.get("#{$props['service_base_url']}/hash/#{jobid}")
end

Given(/^I fresh start the service$/) do
  if check_service
    stop_service
  end
  start_service
end

And(/^the stats should be in the starting state$/) do
  $response = service_getstats
  assert $response.code==200, "Error code getting stats after fresh start of service"
  body = JSON.parse ($response.body)
  assert body['TotalRequests'].to_i == 0, "Total requests not set to 0"
  assert body['AverageTime'].to_f == 0, "Average time not set 0"
end

When(/^I send (\d+) requests for password hashes with jobid (.+)/) do |num, id|
  (1..num.to_i).each do |x|
    submit_job("#{id}#{x}","#{id}#{x}")
  end
end

Then(/^the service should not shutdown until the hash value is available for id (.+)$/) do |id|
  jobid = $bridge['jobs'][id]['response'].body.to_i
  $response = HTTParty.get("#{$props['service_base_url']}/hash/#{jobid}")
  puts $response.code
  puts $response.body
end

Before ('@service-auto-start') do
  start_service unless check_service
end

After ('@service-auto-stop') do
  stop_service
end

at_exit do
  stop_service unless !check_service
end

def start_service
  #bit of a hack, you'd probably want something more robust for starting the service
  begin
    fork {system("export PORT=8088; #{$props['service_path']}")}
    #if we actually are starting the service right now, resets our stats object
    $stats = Hash.new
    sleep 2     #give it a few seconds to start
  rescue
    #ignore errors for now, for reals you'd want to do some checking here to see what happened
  end

end

def stop_service
  #curl -X POST -d 'shutdown' http://127.0.0.1:8088/hash
  system ("curl -X POST -d 'shutdown' http://127.0.0.1:8088/hash")
end

def check_service
  #down and dirty quick way to see if service is currently running, get the stats
  begin
    result = HTTParty.get("#{$props['service_base_url']}/stats")
    up = (result.code == 200)
  rescue
    up = false
  end

  return up
end

def service_getstats
  HTTParty.get("#{$props['service_base_url']}/stats")
end

def submit_job (id, password)
  body = {"password" => password}
  $response=HTTParty.post "#{$props['service_base_url']}/hash", :body=>body.to_json

  $bridge['internal']['count'] = $bridge['internal']['count'] + 1
  $bridge['jobs'][id] = {"password" => password, "response" => $response}
end

def get_hash(id, newid)
  jobid = $bridge['jobs'][id]['response'].body
  $response = HTTParty.get("#{$props['service_base_url']}/hash/#{jobid}")
  $bridge['hashes'][newid] = $response
  return $response
end



