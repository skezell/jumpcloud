Feature: Hash Service

  #anything tagged with service-auto-start will ensure that the service is up before doing the steps
  #anything tagged with service-auto-stop will stop the service after the steps
  #This is included so that you can have scenarios that need additional control over service lifetime

#------------------------------ HAPPY PATH -----------------------------------------------------------------------
  @service-auto-start
  Scenario: Happy Path for hash endpoint POST & GET
    When I submit a job for password [angrymonkey] with id happy
    Then the job response for happy should be valid
    When I wait 10 seconds
    And request the hash value for id happy and save it with id happy-hash
    Then the hash for job happy and response happy-hash should match
    And the service status is true

  @service-auto-start
  Scenario: Happy Path for stats endpoint (checks also that ONLY hash posts are being counted)
    When I submit a password [hello, world] and get the corresponding hash value
    When I submit a password [Anybody want a peanut?] and get the corresponding hash value
    When I request the service stats with id happy-stats
    And the stats with id happy-stats should match the expected stats
    Then the service status is true

  #DEFECT: request is not returning immediately with jobid, it appears to take about 5 sec
  #5 sec is way too long, but I'd likely check with developer for bounds on what would be 'immediately'
  #since Ruby/Cucumber have some overhead that might skew looking at response time, I created a shell script
  #to double check this: ./testtiming.sh
  @service-auto-start
  Scenario: Check response time for initial job submittal
    When I submit a password [hello, world] and get the corresponding hash value
    Then the time for the last request should be between 0 and 3 seconds
    Then the service status is true

  #DEFECT: Timing is not matching my timing, which is generally around 5 seconds per POST
  # As noted in the readme, the spec was a little unclear on what is being measured... more testing is really required
  # after clarification with the developer on what should be measured
  Scenario: Happy Path Check timing stats
    Given I fresh start the service
    And I send 10 requests for password hashes with jobid tenish
    When I request the service stats with id stats
    Then the stats with id stats should match the expected stats
    And the average time from stats should match the expected average time

#------------------------------ EDGE CASES FOR HASH REQUEST (POST) ----------------------------------------------------
  #DEFECT: I was expecting something in the 400 range to indicate a malformed request
  #instead it returns a 200 and jobid
  #requesting the hash for the jobid returns a string (for what I am not sure, empty string perhaps ;)
  #does not crash the service, even though it doesn't get to that step
  @service-auto-start
  Scenario: INVALID Hash request missing password key
    When I submit a job with an invalid body with id missing-password
    Then the last response should be 400 with message [Invalid Request]
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

  #Limit for length of message the sha512 algorithm can handle is 2^128-1
  #Documentation on this algorithm here: https://en.wikipedia.org/wiki/SHA-2
  #UNDONE: Ruby can't hold a string this big, so we're doing 2^16-1 length for now
  #and really we should create a curl test that uses a file with the string saved in it
  #instead of generating it on the fly
  @service-auto-start @slow
  Scenario: Request hash value for a very big password
    When I submit a job with the max password with id bigrandom
    Then the job response for bigrandom should be valid
    When I wait 10 seconds
    And request the hash value for id bigrandom and save it with id bigrandom-hash
    Then the hash for job bigrandom and response bigrandom-hash should match
    And the service status is true

  #UNDONE: can't implement this test case in Ruby (see previous scenario), included for completeness
  #should create a curl request similar to the above scenario to cover this test case and
  #just shell out to that curl request for this scenario
  @service-auto-start
  Scenario: Request hash value for password that exceeds limit for SHA512 input
    Given NYI Can't implement in Ruby, check in another way

  @service-auto-start
  Scenario: Request hash value with JSON meaningful characters
    When I submit a job with a special character password with the id special
    Then the job response for special should be valid
    When I wait 10 seconds
    And request the hash value for id special and save it with id special-hash
    Then the hash for job special and response special-hash should match
    And the service status is true

#------------------------------ EDGE CASES FOR HASH VALUE (GET) ------------------------------------------------------
  #DEFECT: this scenario returns an unexpected message strconv.Atoi: parsing "hash": invalid syntax
  #I was expecting something about jobid not found
  # rather than something that is giving information about what it is expecting for the jobid
  # (both for clarity and for security reasons)
  @service-auto-start
  Scenario: INVALID Get hash with missing jobid
    When I request the hash value without a jobid
    Then the last response should be 400 with message [Hash not found]
    And the service status is true

  @service-auto-start
  Scenario: INVALID Get hash with invalid jobid (number that doesn't exist as a job id yet)
    When I request the hash value for a jobid -1
    Then the last response should be 400
    When I request the hash value for a jobid 100000000
    Then the last response should be 400
    And the service status is true

  #Since jobids appear to be sequential numbers, check really big number
  #DEFECT: Expecting 'Hash not found' but got this error message
  #strconv.Atoi: parsing "1000000000000000000000000000000000000": value out of range
  @service-auto-start
  Scenario: Get hash with very large jobid
    When I request the hash value for a jobid 1000000000000000000000000000000000000
    Then the last response should be 400 with message [Hash not found]
    And the service status is true

  #DEFECT: this scenario returns an unexpected message strconv.Atoi: parsing "hash": invalid syntax
  #I was expecting 'Hash not found' rather than something that is giving information about
  #what it is expecting for the jobid (both for clarity and for security reasons)
  @service-auto-start
  Scenario: INVALID Get hash with invalid jobid (alpha)
    When I request the hash value for a jobid a
    Then the last response should be 400 with message [Hash not found]
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
    When I request the service stats with id stats
    Then the stats with id stats should match the expected stats
    And the service status is true

  #NOTE: this is kind of no-op due to the defect with the service not returning the jobid immediately
  #the scenario will fail - but it's not testing the thing that is intended, really
  @service-auto-start
  Scenario: Request hash value before 5 seconds (before value is calculated yet)
    When I submit a password [infinite monkey cage] and get the corresponding hash value
    Then the last response should be 400 with message [Hash not ready]
    And the service status is true

#------------------------------ MORE STATS ---------------------------------------------------------
  Scenario: Get stats before any jobs submitted
    Given I fresh start the service
    When I request the service stats with id first-stats
    Then the service status is true
    And the stats should be in the starting state

  #NOTE: I didn't have time to run with the real limit 2147483648, which I picked to exceed the integer limit
  @service-auto-start @slow
  Scenario: Get stats very large number of requests (so stats or queue might exceed counters, 2147483648)
    When I send 1000 requests for password hashes with jobid lotsa
    And I request the service stats with id big-stats
    Then the stats with id big-stats should match the expected stats
    And the service status is true

#------------------------------ GRACEFUL SHUTDOWN ---------------------------------------------------------
  @service-auto-start
  Scenario: Happy Path Graceful shutdown
    When I shutdown the service
    And I wait 2 seconds
    Then the service status is false

  #NOTE: See assumptions about this scenario in the readme
  #DEFECT: Service is not allowing last request to complete before shutting down
  @service-auto-start
  Scenario: Graceful shutdown with requests pending
    And I submit a job for password [angrymonkey] with id last
    And I shutdown the service
    Then request the hash value for id last and save it with id last-hash
    And the hash for job last and response last-hash should match
    And the service status is false

  #NOTE: I'm having a hard time getting the service into a state where I can check the service rejects new requests.
  #This applies to a bunch of these shutdown scenarios. Leaving them all in for completeness, but not really testing
  #what was intended!
  @service-auto-start
  Scenario: Graceful shutdown with attempt to submit new job
    Given I submit a job for password [first] with id first
    When I shutdown the service
    And I submit a job for password [late again] with id after
    Then the last response should be 400 with message [No new hash requests accepted]
    
  @service-auto-start
  Scenario: Repeated shutdown commands while graceful shutdown is already in progress
    Given I submit a job for password [Zachary] with id z
    When I shutdown the service
    And I shutdown the service
    And I shutdown the service
    When request the hash value for id z and save it with id z-hash
    Then the service status is false
    
  @service-auto-start
  Scenario: Graceful shutdown with multiple attempts to submit new job
    Given I submit a job for password [first] with id first
    When I shutdown the service
    And I submit a job for password [late again] with id late
    Then the last response should be 400 with message [No new hash requests accepted]
    And I submit a job for password [even later] with id later
    Then the last response should be 400 with message [No new hash requests accepted]

  @service-auto-start
  Scenario: Graceful shutdown with GET of stats 
    Given I submit a job for password [first] with id first
    When I shutdown the service
    And I request the service stats with id stats
    Then the stats with id stats should match the expected stats

#------------------------------ COMPLEX USE CASES ---------------------------------------------------------
  #DEFECT: The service is not behaving correctly with multiple simultaneous requests
  # at 2 requests, the stats aren't getting updated correctly (current failure)
  # at 10, a bunch of the requests are getting rejected (see console window)
  # curl: (7) Failed to connect to 127.0.0.1 port 8088: Connection refused & stats aren't correct
  @service-auto-start
  Scenario: Get stats with multiple simultaneous requests
    When I send 10 simultaneous requests for password hashes with jobid lotsa
    When I request the service stats with id stats
    Then the service status is true
    And the stats with id stats should match the expected stats

  @service-auto-start
  Scenario: Complex scenario (many requests over time, periodic checks on the stats, eventually graceful shutdown)
    When I request the service stats with id start-stats
    Then the stats with id start-stats should match the expected stats
    When I send 5 requests for password hashes with jobid five
    And I submit a job for password [singleton] with id singleton
    And I send 3 requests for password hashes with jobid three
    And I request the hash value for a jobid bogus
    And request the hash value for id singleton and save it with id singleton-hash
    Then the hash for job singleton and response singleton-hash should match
    When I request the service stats with id middle-stats
    Then the stats with id middle-stats should match the expected stats
    When I shutdown the service
    Then the service status is false

  @service-auto-start
  Scenario: Ensure memory is cleared on shutdown
    Given I submit a job for password [Joshua] with id j
    And request the hash value for id j and save it with id j-hash
    Given I fresh start the service
    Then the stats should be in the starting state
    When request the hash value for id j and save it with id j-hash-2
    Then the last response should be 400 with message [Hash not found]




























