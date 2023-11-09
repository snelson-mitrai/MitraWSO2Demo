import ballerina/log;
import ballerina/mime;
import ballerina/soap.soap12;
import ballerina/sql;
import ballerina/time;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/rabbitmq;

final mysql:Client integrationDbClient = check new (
    host = dbHost, user = dbUser, password = dbPassword, port = 3306, database = integrationDb
);

xmlns "http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models" as nup;

@rabbitmq:ServiceConfig {
    queueName,
    autoAck: false
}
service rabbitmq:Service on new rabbitmq:Listener(rabbitMqHost, rabbitMqPort, connectionData = {username: rabbitMqUser, password: rabbitMqPassword, virtualHost: rabbitMqVhost}) {
    remote function onMessage(TaskMessage message, rabbitmq:Caller caller) returns error? {
        do {
            IntegrationTask task = message.content.integrationTask;
            log:printInfo("received order template sync task" , task = task);
            check performSyncOnMinfos(message.content.updatedTemplate);
            check updateIntegrationLogTable(task.TaskId, "Complete", task.Scope);
            check caller->basicAck();
        } on fail error taskError {
            check caller->basicNack(requeue = true);
            log:printError(string `error occurred while processing the task: ${taskError.message()}. re-queued the task.`, taskError);
            return taskError;
        }
    }
}

function performSyncOnMinfos(IO_DWH_OrderTemplate updatedTemplate) returns error? {
    soap12:Client soapClient = check new (mockServerUrl);
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
    xml createTemplate =
        xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:CreateOrderTemplate>
         <tem:request>
            <nup:Template>
               <nup:Description>${updatedTemplate.Description}</nup:Description>
               <nup:RunDate>${updatedTemplate.RunDate.toString()}</nup:RunDate>
               <nup:RunFrequency>${updatedTemplate.RunFrequency}</nup:RunFrequency>
               <nup:Supplier>${updatedTemplate.Supplier}</nup:Supplier>
            </nup:Template>
         </tem:request>
      </tem:CreateOrderTemplate>
   </soapenv:Body>
</soapenv:Envelope>`;
    return createTemplate;
}

function getEditTemplate(IO_DWH_OrderTemplate updatedTemplate) returns xml<xml:Element|xml:Comment|xml:ProcessingInstruction|xml:Text>|mime:Entity[] {
    xml editTemplate =
        xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:EditOrderTemplate>
         <tem:request>
            <nup:Template>
               <nup:Description>${updatedTemplate.Description}</nup:Description>
               <nup:RunDate>${updatedTemplate.RunDate.toString()}</nup:RunDate>
               <nup:RunFrequency>${updatedTemplate.RunFrequency}</nup:RunFrequency>
               <nup:Supplier>${updatedTemplate.Supplier}</nup:Supplier>
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

isolated function updateIntegrationLogTable(int taskID, string status, string scope) returns error? {
    sql:ExecutionResult result = check integrationDbClient->execute(`
        INSERT INTO Log (TaskID, Status, Scope, Timestamp)
        VALUES (${taskID}, ${status}, ${scope}, ${time:utcNow()})
    `);
    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        log:printInfo("Logged status " + status + " for the task " + taskID.toString() + ".");
    } else {
        return error("Unable to obtain last insert ID for the log.");
    }
}

configurable string queueName = "q_order_template_sync";
configurable string mockServerUrl = ?;
configurable int rabbitMqPort = ?;
configurable string rabbitMqHost = ?;
configurable string rabbitMqUser = ?;
configurable string rabbitMqPassword = ?;
configurable string rabbitMqVhost = ?;

configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbHost = ?;
configurable string integrationDb = ?;

type TaskMessage record {|
    *rabbitmq:AnydataMessage;
    TaskData content;
|};

type TaskData record {|
    IntegrationTask integrationTask;
    IO_DWH_OrderTemplate updatedTemplate;
|};

type IntegrationTask record {|
    int TaskId;
    time:Civil CreatedDatetime;
    time:Civil ModifiedDatetime;
    time:Utc ValidFromUTC;
    time:Utc ValidToUTC;
    string Type;
    string Scope;
|};

type IO_DWH_OrderTemplate record {|
    int TemplateID;
    string Category;
    int CategoryRangeEnd;
    int CategoryRangeStart;
    int CompanyRangeEnd;
    int CompanyRangeStart;
    int DeliveryTime;
    string Description;
    boolean IncludeBuyingDeals;
    boolean IncludeNegatives;
    boolean IncludeOutOfStocks;
    boolean IncludeUncollectedScripts;
    string OrderContent;
    int OrderPeriodDays;
    string OrderType;
    int RoundUpAfter;
    time:Date RunDate;
    string RunFrequency;
    int ShelfPackRound;
    string Supplier;
    boolean UseDefaultSuppliers;
    int ZFactor;
|};
