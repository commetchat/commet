# Integration Testing

To run unit tests, there are a few prerequisites.

 - Run Code Generation [scripts/codegen.dart](../scripts/codegen.dart)
 - Configure environment variables [. scripts/setup-env.sh](../scripts/setup-env.sh)
 - Start the synapse docker server [scripts/integration-server-synapse.sh](../scripts/integration-server-synapse.sh)
 - Configure synapse [scripts/integration-prepare-homeserver.sh](../scripts/integration-server-synapse.sh)

 If you have done all this you should be ready to test! [scripts/integration-test.sh](../scripts/integration-test.sh)
