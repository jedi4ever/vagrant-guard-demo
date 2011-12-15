# The purpose is to write tests independent of the way they are executed
Feature: testing vagrant testing

  Scenario: example of an interactive session
    Given I connect to a running system interactively
    When I type "id -a"
    And I disconnect
    Then the output should match /vagrant/
    Then the exit status should be 0

  Scenario: example of a one shot run , non-zero exit status
    Given I execute `cat /etc/passwd|grep \\"vagrant\\"` on a running system
    And the output should match /vagrant/
    Then the exit status should be 0

  Scenario: testing exit status of command
    When I execute `exit 56` on a running system
    Then the exit status should be 56
    And the exit status should not be 0

  Scenario: testing if puppet can run ok
    When I execute `puppet --version` on a running system
    And the exit status should not be 0
