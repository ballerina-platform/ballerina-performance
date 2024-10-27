import ballerina/http;
import ballerina/io;

const epTrustStorePath = "ballerinaTruststore.p12";
configurable string password = ?;
configurable string host = "localhost";
configurable int port = 9090;
configurable string token = ?;
configurable string balInstallerUrl = ?;
configurable string repoUrl = ?;
configurable string branch = ?;

public function main() returns error? {
    http:Client 'client = check new (string `${host}:${port}`,
        secureSocket = {
            cert: {
                path: epTrustStorePath,
                password: password
            },
            verifyHostName: false
        }
    );

    TestConfig config = {
        token,
        balInstallerUrl,
        repo: {
            url: repoUrl,
            branch
        }
    };
    string|record {|string message;|} response = check 'client->/triggerPerfTest.post(config);
    if response !is string {
        return error(string `failed to trigger the performance test due to ${response.message}`);
    }
    io:println("Performance test triggered successfully");
}

type Repo readonly & record {|
    string url;
    string branch;
|};

type TestConfig readonly & record {|
    string balInstallerUrl;
    string token;
    Repo repo;
|};
