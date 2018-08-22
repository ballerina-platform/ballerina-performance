import ballerina/io;
import ballerina/log;
import ballerina/http;

@http:WebSocketServiceConfig {
    path: "/basic/ws",
    subProtocols: ["xml", "json"],
    idleTimeoutInSeconds: 120
}
service<http:WebSocketService> basic bind { port: 9090 } {

    string ping = "ping";
    byte[] pingData = ping.toByteArray("UTF-8");

    onOpen(endpoint caller) {
        io:println("\nNew client connected");
        io:println("Connection ID: " + caller.id);
        io:println("Negotiated Sub protocol: " + caller.negotiatedSubProtocol);
        io:println("Is connection open: " + caller.isOpen);
        io:println("Is connection secured: " + caller.isSecure);
    }

    onText(endpoint caller, string text, boolean final) {

        if (text == "ping") {
            io:println("Pinging...");
            caller->ping(pingData) but { error e => log:printError("Error sending ping", err = e) };
        } else if (text == "closeMe") {
            caller->close(1001, "You asked me to close the connection")
            but { error e => log:printError("Error occurred when closing the connection", err = e) };
        } else {
            caller->pushText(text) but { error e => log:printError("Error occurred when sending text",
                err = e) };
        }
    }

    onBinary(endpoint caller, byte[] data) {
        io:println("\nNew binary message received");
        caller->pushBinary(data) but { error e => log:printError("Error occurred when sending binary", err = e) };
    }

    onPing(endpoint caller, byte[] data) {
        caller->pong(data) but { error e => log:printError("Error occurred when closing the connection", err = e) };
    }

    onPong(endpoint caller, byte[] data) {
        io:println("Pong received");
    }

    onIdleTimeout(endpoint caller) {
        io:println("\nReached idle timeout");
        io:println("Closing connection " + caller.id);
        caller->close(1001, "Connection timeout") but {
            error e => log:printError("Error occured when closing the connection", err = e)
        };
    }

    onClose(endpoint caller, int statusCode, string reason) {
        io:println("\nClient left with status code " + statusCode + " because " + reason);
    }
}
