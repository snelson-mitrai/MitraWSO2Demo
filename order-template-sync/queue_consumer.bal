import ballerina/log;
import ballerina/mime;
import ballerina/soap.soap12;
import ballerinax/rabbitmq;

rabbitmq:ConnectionConfiguration config = {username: RABBITMQ_USER, password: RABBITMQ_PW, virtualHost: RABBITMQ_VHOST};
xmlns "http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models" as nup;

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
    if response is xml {
        if !templateExists(response) {
            _ = check soapClient->sendOnly(getCreateTemplate(updatedTemplate), "http://tempuri.org/IOrdersService/CreateOrderTemplate");
            log:printInfo("Order template created.");
        } else if templateUpdated(updatedTemplate, response) {
            check soapClient->sendOnly(getEditTemplate(updatedTemplate), "http://tempuri.org/IOrdersService/EditOrderTemplate");
            log:printInfo("Order template edited.");
        }
    }
}

function getCreateTemplate(IO_DWH_OrderTemplate updatedTemplate) returns xml<xml:Element|xml:Comment|xml:ProcessingInstruction|xml:Text>|mime:Entity[] {
    string desc = updatedTemplate.Description;
    string runDate = updatedTemplate.RunDate.toString();
    string freq = updatedTemplate.RunFrequency;
    string supplier = updatedTemplate.Supplier;
    xml createTemplate =
        xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:CreateOrderTemplate>
         <tem:request>
            <nup:Template>
               <nup:Description>${desc}</nup:Description>
               <nup:RunDate>${runDate}</nup:RunDate>
               <nup:RunFrequency>${freq}</nup:RunFrequency>
               <nup:Supplier>${supplier}</nup:Supplier>
            </nup:Template>
         </tem:request>
      </tem:CreateOrderTemplate>
   </soapenv:Body>
</soapenv:Envelope>`;
    return createTemplate;
}

function getEditTemplate(IO_DWH_OrderTemplate updatedTemplate) returns xml<xml:Element|xml:Comment|xml:ProcessingInstruction|xml:Text>|mime:Entity[] {
    string desc = updatedTemplate.Description;
    string runDate = updatedTemplate.RunDate.toString();
    string freq = updatedTemplate.RunFrequency;
    string supplier = updatedTemplate.Supplier;
    xml editTemplate =
        xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:EditOrderTemplate>
         <tem:request>
            <nup:Template>
               <nup:Description>${desc}</nup:Description>
               <nup:RunDate>${runDate}</nup:RunDate>
               <nup:RunFrequency>${freq}</nup:RunFrequency>
               <nup:Supplier>${supplier}</nup:Supplier>
            </nup:Template>
         </tem:request>
      </tem:EditOrderTemplate>
   </soapenv:Body>
</soapenv:Envelope>`;
    return editTemplate;
}

function templateUpdated(IO_DWH_OrderTemplate updatedTemplate, xml response) returns boolean {
    string description = (response/**/<nup:Description>).data();
    if description != updatedTemplate.Description {
        return true;
    }
    return false;
}

function templateExists(xml response) returns boolean {
    string created = (response/**/<nup:Created>).data();
    string description = (response/**/<nup:Description>).data();
    if description == "" && created == "" {
        return false;
    }
    return true;
}

xml getTemplates =
        xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetOrderTemplates/>
   </soapenv:Body>
</soapenv:Envelope>`;
