# performance-ballerina-cfn
Ballerina Cloudformation script

# Validate script

    aws cloudformation validate-template --template-body file://ballerina_perf_test_cfn.yaml

# How to run

    aws cloudformation create-stack --stack-name ballerina-test-stack --template-body file://ballerina_perf_test_cfn.yaml --parameters ParameterKey=KeyName,ParameterValue=ballerina-perf-test ParameterKey=PerformanceBallerinaDistributionURL,ParameterValue=https://s3.us-east-2.amazonaws.com/ballerinaperformancetest/performance-ballerina-distribution-0.1.0-SNAPSHOT.tar.gz ParameterKey=KeyFileURL,ParameterValue=https://s3.us-east-2.amazonaws.com/ballerinaperformancetest/ballerina-perf-test.pem
