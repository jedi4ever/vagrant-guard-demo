Feature: apache check

  Scenario: see if the apache header is served
    Given I execute `lynx http://localhost --dump` on a running system
    Then the output should match /It works/
    Then the exit status should be 0

  Scenario: check if the apache config is valid
    Given I execute `apache2ctl configtest` on a running system
    Then the exit status should be 0
