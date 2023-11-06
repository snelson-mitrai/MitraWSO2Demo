import ballerina/log;
import ballerina/mime;
import ballerina/soap.soap12;
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

function performSyncOnMinfos(IO_DWH_OrderTemplate updatedTemplate) returns error? {
    soap12:Client soapClient = check new ("localhost:8086");
    xml|mime:Entity[] response = check soapClient->sendReceive(getTemplates, "http://tempuri.org/IOrdersService/GetOrderTemplates");
    log:printInfo(response.toString());
    if response is xml {
        if !templateExists(updatedTemplate, response) {
            _ = check soapClient->sendOnly(createTemplate, "http://tempuri.org/IOrdersService/CreateOrderTemplate");
        } else if templateUpdated(updatedTemplate, response) {
            check soapClient->sendOnly(editTemplate, "http://tempuri.org/IOrdersService/EditOrderTemplate");
        }
    }
}

function templateUpdated(IO_DWH_OrderTemplate r, xml response) returns boolean {
    return false;
}

function templateExists(IO_DWH_OrderTemplate r, xml response) returns boolean {
    return true;
}

xml getTemplates =
        xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetOrderTemplates/>
   </soapenv:Body>
</soapenv:Envelope>`;

xml createTemplate =
        xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:CreateOrderTemplate>
         <tem:request>
            <nup:Template>
               <nup:Description>The order template that captures Rosuvastin 5 mg water soluable film coated tablets. Prescribed drug only.</nup:Description>
               <nup:RunDate>2023-11-16T00:00:00.000+05:00</nup:RunDate>
               <nup:RunFrequency>FORTNIGHTY</nup:RunFrequency>
               <nup:Supplier>Mylan Australia QLD</nup:Supplier>
            </nup:Template>
         </tem:request>
      </tem:CreateOrderTemplate>
   </soapenv:Body>
</soapenv:Envelope>`;

xml editTemplate =
        xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetOrderTemplates/>
   </soapenv:Body>
</soapenv:Envelope>`;
