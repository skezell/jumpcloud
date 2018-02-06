Feature: Hash Service

  #anything tagged with service-auto-start will ensure that the service is up before doing the steps
  #anything tagged with service-auto-stop will stop the service after the steps
  #This is included so that you can have scenarios that need additional control over service lifetime


  @service-auto-start
  Scenario: Happy Path for hash endpoint POST & GET
    When I submit a job for password [angrymonkey] with id happy
    Then the job response for happy should be valid
    When I wait 10 seconds
    And request the hash value for id happy and save it with id happy-hash
    Then the hash for job happy and response happy-hash should match
    And the service status is true

  @service-auto-start
  Scenario: Happy Path for stats endpoint
    When I request the service stats with id happy-stats
    Then the service status is true
    And the stats with id happy-stats should match the expected stats

  #DEFECT: I was expecting something in the 400 range to indicate a malformed request
  #instead it returns a 200 and jobid
  #requesting the hash for the jobid returns a string (for what I am not sure ;)
  #does not crash the service, even though it doesn't get to that step
  @service-auto-start
  Scenario: INVALID Hash request missing password key
    When I submit a job with an invalid body with id missing-password
    Then the last response should be 400
    And the service status is true

  @service-auto-start
  Scenario: Hash request with empty password
    When I submit a job for password [] with id empty
    Then the job response for empty should be valid
    When I wait 10 seconds
    And request the hash value for id empty and save it with id empty-hash
    Then the hash for job empty and response empty-hash should match
    And the service status is true

  @service-auto-start
  Scenario: Hash requests with extra keys in payload
    When I request a hash value with extra keys in payload with id extra
    Then the job response for extra should be valid
    When I wait 10 seconds
    And request the hash value for id extra and save it with id extra-hash
    Then the hash for job extra and response extra-hash should match
    And the service status is true

  @service-auto-start
  Scenario: Hash request with random (UTF-8) characters
    When I submit a job with a random password of length 100 with id random
    Then the job response for random should be valid
    When I wait 10 seconds
    And request the hash value for id random and save it with id random-hash
    Then the hash for job random and response random-hash should match
    And the service status is true

  #undone: should research sha512 information to determine a more realistic upper limit, I'm sure it's way bigger
  #than 10000
  @service-auto-start @slow
  Scenario: Request hash value for a very big password
    When  I submit a job with a random password of length 10000 with id bigrandom
    Then the job response for bigrandom should be valid
    When I wait 10 seconds
    And request the hash value for id bigrandom and save it with id bigrandom-hash
    Then the hash for job bigrandom and response bigrandom-hash should match
    And the service status is true

  @service-auto-start
  Scenario: Request hash value with JSON meaningful characters
    When I submit a job with a special character password with the id special
    Then the job response for special should be valid
    When I wait 10 seconds
    And request the hash value for id special and save it with id special-hash
    Then the hash for job special and response special-hash should match
    And the service status is true

  #POSSIBLE DEFECT: this scenario returns an unexpected message strconv.Atoi: parsing "hash": invalid syntax
  #I was expecting something about jobid not found, rather than something that is giving information about
  #what it is expecting for the jobid (both for clarity and for security reasons)
  @service-auto-start
  Scenario: INVALID Get hash with missing jobid
    When I request the hash value without a jobid
    Then the last response should be 400
    And the service status is true

  @service-auto-start
  Scenario: INVALID Get hash with invalid jobid (number that doesn't exist as a job id yet)
    When I request the hash value for a jobid 100000000
    Then the last response should be 400
    And the service status is true

  #POSSIBLE DEFECT: this scenario returns an unexpected message strconv.Atoi: parsing "hash": invalid syntax
  #I was expecting something about jobid or hash not found, rather than something that is giving information about
  #what it is expecting for the jobid (both for clarity and for security reasons)
  @service-auto-start
  Scenario: INVALID Get hash with invalid jobid (alpha)
    When I request the hash value for a jobid a
    Then the last response should be 400
    And the service status is true

  @service-auto-start
  Scenario: Multiple hash value requests for same jobid
    When I submit a job for password [angrymonkey] with id askagain
    Then the job response for askagain should be valid
    When I wait 10 seconds
    And request the hash value for id askagain and save it with id askagain-hash
    Then the hash for job askagain and response askagain-hash should match
    And request the hash value for id askagain and save it with id askagain-hash2
    Then the hash for job askagain and response askagain-hash2 should match
    And request the hash value for id askagain and save it with id askagain-hash3
    Then the hash for job askagain and response askagain-hash3 should match
    And the service status is true

  #POSSIBLE DEFECT: as near as I can tell, I can get the hash before the 5 secs have elapsed (see the curl script for
  #faster execution since cucumber and httparty all have a little overhead) which is not to spec
  #I was expecting some kind of error code or message that it hadn't calculated yet if I asked for it before the
  #delay had elapsed
  @service-auto-start
  Scenario: Request hash value before 5 seconds (before value is calculated yet)
    When I submit a job for password [hello world] with id quick
    And request the hash value for id quick and save it with id quick-hash
    Then the last response should be 400
    And the service status is true

  Scenario: Get stats before any jobs submitted
    Given I fresh start the service
    When I request the service stats with id first-stats
    Then the service status is true
    And the stats should be in the starting state

  #POSSIBLE DEFECT: It appears that it is not returning the jobid immediately and processing the hash calculations
  #asynchronously. The service appears to process about 10 requests/minute, unexpectedly low.
  #More investigation, probably not from ruby/cucumber (use curl) just to rule out any overhead the framework introduces
  # though other tests that I have don't show this level of overhead against REST Api's
  @service-auto-start
  Scenario: Get stats with multiple requests pending
    When I send 10 requests for password hashes with jobid lotsa
    When I request the service stats with id lotsa-stats
    Then the service status is true
    And the stats with id lotsa-stats should match the expected stats

  @service-auto-start
  Scenario: Happy Path Graceful shutdown
    When I shutdown the service
    And I wait 2 seconds
    Then the service status is false

  @service-auto-start @debug
  Scenario: Graceful shutdown with requests pending
    When I send 100 requests for password hashes with jobid lotsa-shutdown
    And I submit a job for password [angrymonkey] with id last
    And I shutdown the service
    Then the service should not shutdown until the hash value is available for id last

  @service-auto-start
  Scenario: Graceful shutdown with attempt to submit new job
    When I send 1000 requests for password hashes with jobid lotsa
    And I request the hash value for password [angrymonkey] with id the-last
    When I shutdown the service
    And I request the hash value for password [angrymonkey] with id angry
    Then the request should be rejected
    Then the service should not shutdown until the hash value is available for id the-last

  @service-auto-start
  Scenario: Repeated shutdown commands while graceful shutdown is already in progress
    When I send 1000 requests for password hashes with jobid lotsa
    And I request the hash value for password [angrymonkey] with id the-last
    When I shutdown the service
    And I shutdown the service
    And I shutdown the service
    Then the service should not shutdown until the hash value is available for id the-last

  @service-auto-start
  Scenario: Get status very large number of requests (so stats might exceed counters)
    When I send 1000000000 requests for password hashes with jobid lotsa
    And I request the hash value for all requests submitted
    And I request the service stats with id big-stats
    Then the stats with id big-stats should match the expected stats
    And the service status is true

  @service-auto-start
  Scenario: Complex scenario (many requests over time, periodic checks on the stats, eventually graceful shutdown)
    #get stats
    #submit 100 requests and ask for each value back
    #get stats
    #submit more requests & check all values (even those above)
    #submit a bunch to have some pending
    #shutdown
    #request stats
    #request some values
    #multiple attempts to submit new jobs
    #check that the last hash is processed
    #check that after last hash, it shutsdown























