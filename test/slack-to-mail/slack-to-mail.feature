Feature: Slack To Mail

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
    Given load Kamelet slack-source.kamelet.yaml
    Given load Kamelet mail-sink.kamelet.yaml
    When load Kubernetes custom resource slack-to-mail.yaml in kameletbindings.camel.apache.org
    Then Kamelet slack-source is available
    And Kamelet mail-sink is available
    And Camel-K integration slack-to-mail should be running

  Scenario: Send Slack message
    Given URL: https://slack.com
    And HTTP request header Authorization="Bearer ${slack.token}"
    And HTTP request header Content-Type="application/json"
    And HTTP request body
    """
    {
      "channel": "${slack.channel}",
      "text":"${message}"
    }
    """
    When send POST /api/chat.postMessage
    Then receive HTTP 200 OK

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
        "content": "\"${message}\"",
        "attachments": null
      }
    }
    """

  Scenario: Remove Camel-K resources
    Given delete KameletBinding slack-to-mail
    And delete Kamelet mail-sink
    And delete Kamelet slack-source
    And delete Kubernetes service mail-server
