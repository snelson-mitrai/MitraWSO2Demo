import ballerina/http;
import ballerina/log;
import ballerinax/rabbitmq;

service / on new http:Listener(8080) {
    private final rabbitmq:Client taskQueueClient;

    function init() returns error? {
        self.taskQueueClient = check new (RABBITMQ_HOST, RABBITMQ_PORT);
    }

    isolated resource function post .(@http:Payload EventData event) returns error? {
        do {
            IntegrationTask orderTemplateSyncTask = check lookUpIntegrationTaskTable(event);
            log:printInfo("Order template sync task received.");

            check updateIntegrationLogTable(orderTemplateSyncTask.TaskId, "In-Progress", orderTemplateSyncTask.Scope);

            IO_DWH_OrderTemplate updatedTemplate = check lookUpUpdatedOrderTemplate(event.templateID);
            TaskMessage taskMessage = {
                content: {integrationTask: orderTemplateSyncTask, updatedTemplate: updatedTemplate},
                routingKey: queueName
            };
            check self.taskQueueClient->publishMessage(taskMessage);
        } on fail error err {
            log:printError(string `Error occurred while queuing the task: ${err.message()}`, err);
            return err;
        }
    }
}
