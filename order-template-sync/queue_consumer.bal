import ballerina/log;
// import ballerina/mime;
// import ballerina/soap.soap12;
import ballerinax/rabbitmq;

@rabbitmq:ServiceConfig {
    queueName: queueName,
    autoAck: false
}
service rabbitmq:Service on new rabbitmq:Listener(RABBITMQ_HOST, RABBITMQ_PORT) {
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
    // todo
    // soap12:Client soapClient = check new ("http://www.dneonline.com/calculator.asmx?WSDL");

    // xml envelope =
    //     xml `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
    //         <soap:Body>
    //         <quer:Add xmlns:quer="http://tempuri.org/">
    //         <quer:intA>2</quer:intA>
    //         <quer:intB>3</quer:intB>
    //         </quer:Add>
    //         </soap:Body>
    //         </soap:Envelope>`;
    // xml|mime:Entity[] response = check soapClient->sendReceive(envelope, "http://tempuri.org/Add");
    log:printInfo("Sync on MINFOS completed.");
}
