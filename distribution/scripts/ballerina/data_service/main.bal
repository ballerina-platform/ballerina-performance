import ballerina/http;
import ballerina/log;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string dbUser = ?;
configurable string dbPassword = ?;
configurable string dbHost = ?;
configurable int dbPort = ?;
configurable string dbName = ?;
configurable string epKeyPath = ?;
configurable string epKeyPassword = ?;

type Order record {|
    string symbol;
    string buyerID;
    float price;
    int volume;
|};

type DBOrder record {|
    int id;
    string symbol;
    string buyerID;
    float price;
    int volume;
|};

type Invoice record {|
    Order[] 'order;
|};

type Request record {|
    string size;
    Invoice payload;
|};

listener http:Listener securedEP = new (9090,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: epKeyPassword
        }
    }
);

final mysql:Client dbClient = check new (
    host = dbHost,
    user = dbUser,
    password = dbPassword,
    port = dbPort,
    database = dbName
);

service /'orders on securedEP {

    isolated resource function post .(Request request) returns int|error? {
        sql:ParameterizedQuery[] insertQueries = from Order 'order in request.payload.'order
            select `INSERT INTO Orders (symbol, buyerID, price, volume)
            VALUES (${'order.symbol}, ${'order.buyerID}, ${'order.price}, ${'order.volume})`;
        sql:ExecutionResult[] result = check dbClient->batchExecute(insertQueries);
        int|string? lastInsertId = result[0].lastInsertId;
        if lastInsertId is int {
            return lastInsertId;
        }
        return error("Unable to obtain last insert ID");
    }

    isolated resource function get [int id]() returns Order|error? {
        log:printInfo(id.toString());
        DBOrder dbOrder = check dbClient->queryRow(
            `SELECT * FROM Orders WHERE id = ${id}`
        );
        return convertDBOrderToOrder(dbOrder);
    }

    isolated resource function get .() returns Order[]|error? {
        Order[] orders = [];
        stream<DBOrder, error?> resultStream = dbClient->query(
            `SELECT * FROM Orders`
        );
        check from DBOrder dbOrder in resultStream
            do {
                orders.push(convertDBOrderToOrder(dbOrder));
            };
        check resultStream.close();
        return orders;
    }

    isolated resource function put [int id](Order 'order) returns int|error? {
        sql:ExecutionResult result = check dbClient->execute(`
            UPDATE Orders SET
                symbol = ${'order.symbol}, 
                buyerID = ${'order.buyerID},
                price = ${'order.price},
                volume = ${'order.volume}
            WHERE id = ${id}
        `);
        int? affectedRowCount = result.affectedRowCount;
        if affectedRowCount is int {
            return affectedRowCount;
        }
        return error("Unable to obtain affectedRowCount");
    }

    isolated resource function delete [int id]() returns int|error? {
        sql:ExecutionResult result = check dbClient->execute(`
            DELETE FROM Orders WHERE id = ${id}
        `);
        int? affectedRowCount = result.affectedRowCount;
        if affectedRowCount is int {
            return affectedRowCount;
        }
        return error("Unable to obtain the affected row count");
    }

}

isolated function convertDBOrderToOrder(DBOrder dbOrder) returns Order =>
    {
    symbol: dbOrder.symbol,
    buyerID: dbOrder.buyerID,
    price: dbOrder.price,
    volume: dbOrder.volume
};
