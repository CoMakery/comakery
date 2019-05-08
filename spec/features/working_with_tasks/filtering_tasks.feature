Feature: Filtering tasks
  ...

  Background:
    Given I am a logged in user
    And I am viewing my tasks

  Scenario Outline: A contributor can filter tasks
    Given I have Ready, Started, Submitted, Accepted, Paid, Rejected tasks as a contributor
    When I want to see only <filter> tasks
    Then I should see only <statuses> tasks

    Scenarios:
      | filter    | statuses            |
      | ready     | ready               |
      | started   | started             |
      | submitted | submitted, accepted |
      | to review | no                  |
      | to pay    | no                  |
      | done      | paid, rejected      |

  Scenario Outline: A project owner can filter tasks
    Given I have Ready, Submitted, Accepted, Paid, Rejected tasks as a project owner
    When I want to see only <filter> tasks
    Then I should see only <statuses> tasks

    Scenarios:
      | filter    | statuses       |
      | ready     | ready          |
      | started   | no             |
      | submitted | no             |
      | to review | submitted      |
      | to pay    | accepted       |
      | done      | paid, rejected |
