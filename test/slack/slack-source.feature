Feature: Slack Kamelet

  Background:
    Given Camel-K resource polling configuration
      | maxAttempts          | 200   |
      | delayBetweenAttempts | 2000  |

  Scenario: Create Camel-K resources
    Given load Kamelet slack-source.kamelet.yaml
    Given load Camel-K integration slack-to-log.groovy
    Then Kamelet slack-source is available
    And Camel-K integration slack-to-log should be running

  Scenario: Send Slack message
    Given variables
      | message | ANNOUNCEMENT: v0.citrus:randomString(1) released |
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
    And Camel-K integration slack-to-log should print "${message}"

  Scenario: Remove Camel-K resources
    Given delete Camel-K integration slack-to-log
    And delete Kamelet slack-source
