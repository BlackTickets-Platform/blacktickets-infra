const { PublishCommand, SNSClient } = require("@aws-sdk/client-sns");

const snsClient = new SNSClient({});

const requiredFields = ["eventType", "bookingId", "userId", "eventId", "timestamp"];

const parseRecordBody = (record) => {
  try {
    return JSON.parse(record.body);
  } catch (error) {
    console.error("Invalid SQS message JSON; skipping record.", {
      messageId: record.messageId,
      error: error.message
    });
    return null;
  }
};

const isValidBookingMessage = (message) => {
  return requiredFields.every((field) => message && message[field]);
};

const buildEmailMessage = (message) => {
  return [
    "A BlackTickets booking has been confirmed.",
    "",
    `eventType: ${message.eventType}`,
    `bookingId: ${message.bookingId}`,
    `userId: ${message.userId}`,
    `eventId: ${message.eventId}`,
    `timestamp: ${message.timestamp}`
  ].join("\n");
};

exports.handler = async (event) => {
  const topicArn = process.env.SNS_TOPIC_ARN;

  if (!topicArn) {
    throw new Error("SNS_TOPIC_ARN environment variable is required.");
  }

  for (const record of event.Records || []) {
    const message = parseRecordBody(record);

    if (!isValidBookingMessage(message)) {
      console.error("Invalid booking notification payload; skipping record.", {
        messageId: record.messageId,
        payload: message
      });
      continue;
    }

    try {
      await snsClient.send(
        new PublishCommand({
          TopicArn: topicArn,
          Subject: "BlackTickets Booking Confirmed",
          Message: buildEmailMessage(message)
        })
      );

      console.log("Published booking notification to SNS.", {
        messageId: record.messageId,
        bookingId: message.bookingId,
        eventId: message.eventId
      });
    } catch (error) {
      console.error("Failed to publish booking notification to SNS.", {
        messageId: record.messageId,
        bookingId: message.bookingId,
        topicArn,
        error: error.message
      });
      throw error;
    }
  }
};
