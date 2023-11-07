import ballerina/log;
import ballerina/mime;
import ballerina/soap.soap12;
import ballerinax/rabbitmq;
import ballerina/time;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string  QUEQUE_NAME = "TaskQueue";
configurable string MOCKSERVER_URL = ?;
configurable int RABBITMQ_PORT = ?;
configurable string RABBITMQ_HOST = ?;
configurable string RABBITMQ_USER = ?;
configurable string RABBITMQ_PW = ?;
configurable string RABBITMQ_VHOST = ?;

configurable string DB_USER = ?;
configurable string DB_PASSWORD = ?;
configurable string DB_HOST = ?;
configurable string INTEGRATION_DB = ?;
int DB_PORT = 3306;

rabbitmq:ConnectionConfiguration config = {username: RABBITMQ_USER, password: RABBITMQ_PW, virtualHost: RABBITMQ_VHOST};
xmlns "http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models" as nup;

@rabbitmq:ServiceConfig {
    queueName: QUEQUE_NAME,
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

type IntegrationLog record {|
    int? LogID = ();
    int TaskID;
    string Status;
    string Scope;
    time:Utc Timestamp;
|};

function performSyncOnMinfos(IO_DWH_OrderTemplate updatedTemplate) returns error? {
    soap12:Client soapClient = check new (MOCKSERVER_URL);
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

final mysql:Client integrationDbClient = check new (
    host = DB_HOST, user = DB_USER, password = DB_PASSWORD, port = DB_PORT, database = INTEGRATION_DB
);

isolated function updateIntegrationLogTable(int taskID, string status, string scope) returns error? {
    IntegrationLog log = {
        TaskID: taskID,
        Status: status,
        Scope: scope,
        Timestamp: time:utcNow()
    };

    sql:ExecutionResult result = check integrationDbClient->execute(`
        INSERT INTO Log (TaskID, Status, Scope, Timestamp)
        VALUES (${log.TaskID}, ${log.Status}, ${log.Scope}, ${log.Timestamp})
    `);
    int|string? lastInsertId = result.lastInsertId;
    if lastInsertId is int {
        log:printInfo("Logged status " + log.Status + " for the task " + log.TaskID.toString() + ".");
    } else {
        return error("Unable to obtain last insert ID for the log.");
    }
}
