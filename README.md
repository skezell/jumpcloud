Jumpcloud Automation Assignment
===
By: Suzanne Ezell
Last Updated: 2/3/18

Execution 
---
1. Clone the repo

2. These tests are written and tested with Ruby 2.3.1 (though I'm not aware of using anything that would not work in
any version >= 2.0). For Linux/OSX environments, I'd recommend rvm which lets you easily install ruby versions, 
switch between them and manage gemsets.

[RVM](https://rvm.io/rvm/install)  
[Ruby Installer for Windows](https://rubyinstaller.org/)  

3. You're going to need a few gems (listed in the Gemfile)

    A. First install the bundle gem via this command `gem install bundle`  
    B. Use the bundle gem to fetch all other dependencies via this command `bundle install` into a named 
    gemset OR append `bundle install && ` to your cucumber/ruby command.  
    
4. Check the settings in the default.json and make sure that the url to access the service and the path to the service 
executable are correct. If you want to manually start and stop the service, set the local_service field to false. 
Caveat: for sure a few scenarios will fail if the suite is not controlling the lifecycle of the service (those that
depend on knowing the starting state of the service - it's sort of obvious when you read the scenarios which ones fit 
that bill).

5. To run all the tests, in the root of the repo run this command

`bundle install && cucumber --tags ~@slow --format html --out features_report.html`  
(runs everything but slow tests)
OR
`bundle install && cucumber --format html --out features_report.html` 
(runs everything)
OR
`bundle install && cucumber --tags @service-auto-start --format html --out features_report.html` 
(only scenarios that can be run against a remote service, if you start the service manually, without failing)

and like it suggests, the results are in features_report.html. You can also run inside an IDE like RubyMine and see the
graphical results tree.

6. In case you have trouble running for any reason, I've checked in two results html files from my local run (slow and 
not slow scenarios).

General Information
---

+ I selected test cases in the order I would prioritize without any additional information about requirements or risk.
Generally, one or two happy path scenarios to validate general functionality followed by edge cases and then a few 
complex scenariosw that represents more likely real world scenarios. 

+ I prefer to have the automated tests serve as the documentation for the test cases if at all possible to reduce the
work involved in keeping the documentation up to date. For that reason, the tests are written in Gherkin (Cucumber
syntax).

+ Since I only worked on this assignment for a about 2 days, it's most definitely incomplete. Of note, if this was a 
production service I would likely include

    + Load/Performance/Stress testing
    + Security scenarios, including trying invalid routes, bad payloads, incorrect verbs, etc.
    + Running against a remote server (right now the tests assume running locally for simplicity)
    + Low bandwidth/network disruptions
    + True multiuser scenarios - actually have separate VM's posting requests at the same time
    + Bump up all the numbers, which are set kind of low for speed (e.g. total number of requests)
    
+ A real automated suite should make use of automated environment setup (often these are tied to a CI/CD system) and 
employ a more robust logging of results to either the CI/CD system (e.g. with a cucumber Jenkins plugin) or to a custom
results repository. Helper classes/methods were written to be bare bones and would be way more robust and have more
abstraction with a real solution.

+ Given the stated requirements, I have the following questions that I would likely discuss with the team before
selecting the test cases and might possibly affect the test cases as written, were this a real testing scenario:

    + Does the service generate hashes concurrently or does it only accept multiple requests concurrently and return 
    the job id, but do the actual hash operations sequentially?
    + What is meant by job completion? Since there would be no purpose in allowing the hash computation to finish if 
    the service didn't wait for at least one client to get the hash value back, I'm going with the definition of 
    'completion' as the service has sent the actual hash value back (at least once)
    + Is the average processing time using times to process the initial request/return jobid? or the time to calculate
    the hash for the given password? or both?
    + How many concurrrent users does it need to support? any limits on the number of requests the service can have
    in the queue? limits on the total number of requests between restarts of the service/limits on the stats 
    collection?
    + Requirements for graceful shutdown don't specify which actions should be rejected during shutdown - submitting
    a new job AND requesting a previously calculated hash value OR just submitting new jobs
    + The requirements don't state this, but assuming you can request the hash value for a jobid multiple times? Is
    there a lifetime for this information (before the service is shutdown, which clears memory, I'd presume)?
    
+ Additionally, if I were testing this service for real I'd likely ask the development team about the feasibility of
adding some additional (non public) functionality to make the service more testable:
    + provide a way to reset the stats collection without shutting down the service (shutdown is likely more time
    consuming than just clearing the counters)
    + configurable delay for the processing of requests (to make it easier to test concurrency scenarios)
    + additional information about what jobs are in the queue and have been processed when asking for status
    + a way to flush all or part of the stored hash information or queued jobs (again for speed, you can always
    shutdown the service completely)
    
