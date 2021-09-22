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

  Scenario: Create mail server
    Given load endpoint mail-server.groovy
    Given create Kubernetes service mail-server with port mapping 25:22222

  Scenario: Create Camel-K resources
    Given load Kamelet mail-sink.kamelet.yaml
    Given load KameletBinding timer-to-mail.yaml
    Then Kamelet mail-sink is available
    And Camel-K integration timer-to-mail should be running

  Scenario: Verify mail message sent
    Then endpoint mail-server should receive body
    """
    {
      "from": "${from}",
      "to": "${to}",
      "cc": "",
      "bcc": "",
      "replyTo": "@ignore@",
      "subject": "${subject}",
      "body": {
        "contentType": "text/plain",
        "content": "${message}",
        "attachments": null
      }
    }
    """

  Scenario: Remove Camel-K resources
    Given delete KameletBinding timer-to-mail
    And delete Kamelet mail-sink
    And delete Kubernetes service mail-server
