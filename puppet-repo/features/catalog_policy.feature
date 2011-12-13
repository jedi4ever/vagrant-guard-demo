Feature: Catalog policy
  In order to ensure basic correctness
  I want all catalogs to obey my policy

  Scenario Outline: Generic policy for all server roles
    Given a node with role "<server_role>"
    When I compile its catalog
    Then compilation should succeed
    And all resource dependencies should resolve

    Examples:
      | server_role |
      | role::webserver |
