import ballerina/log;
import ballerinax/rabbitmq;

rabbitmq:ConnectionConfiguration config = {username: RABBITMQ_USER, password: RABBITMQ_PW, virtualHost: RABBITMQ_VHOST};
        
@rabbitmq:ServiceConfig {
    queueName: queueName,
    autoAck: false
}
service rabbitmq:Service on new rabbitmq:Listener(RABBITMQ_HOST, RABBITMQ_PORT, connectionData = config) {
    remote function onMessage(TaskMessage message, rabbitmq:Caller caller) returns error? {
        do {
            IntegrationTask task = message.content.integrationTask;
            log:printInfo("Received order template sync task. Task ID: " + task.TaskId.toString());
            check performSyncOnMinfos(message.content.updatedTemplate);
            check caller->basicAck();
            check updateIntegrationLogTable(task.TaskId, "Complete", task.Scope);
        } on fail error taskError {
            check caller->basicNack(requeue = true);
            log:printError(string `Error occurred while processing the task: ${taskError.message()}. Re-queuing the task.`, taskError);
            return taskError;
        }
    }
}

function performSyncOnMinfos(IO_DWH_OrderTemplate taskData) returns error? {
    log:printInfo("Performed sync on MINFOS - TBD");
}

