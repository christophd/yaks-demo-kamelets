Feature: Mail Sink

  Background:
    Given Camel-K resource polling configuration
      | maxAttempts          | 200   |
      | delayBetweenAttempts | 2000  |
    Given variables
      | host      | mail-server |
      | from      | user@demo.yaks |
      | to        | announcements@demo.yaks |
      | subject   | Release Announcement |
      | message   | ANNOUNCEMENT: v1.0 released |

  Scenario: Verify mail sink
    Given start mail server
    Given load Kamelet mail-sink.kamelet.yaml
    Given load KameletBinding timer-to-mail.yaml
    Then Kamelet mail-sink is available
    And Camel-K integration timer-to-mail should be running
    Then verify mail received

  Scenario: Remove Camel-K resources
    Given delete KameletBinding timer-to-mail
    And delete Kamelet mail-sink
