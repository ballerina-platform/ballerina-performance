# performance-ballerina-cfn
Ballerina Cloudformation script

# How to run

    aws cloudformation create-stack --stack-name ballerina-test-stack --template-body file://ballerina_perf_test_cfn.yaml --parameters ParameterKey=KeyName,ParameterValue=ballerina-perf-test
