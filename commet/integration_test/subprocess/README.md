# Integration Testing Subprocess

This provides a second process to act as a matrix client to interact with during unit testing. Using `matrix-js-sdk` and node.

## Running
To set this up for running, make sure `node` is installed and available on your system PATH

We use Node version 18.

Also install `ts-node` such that it is also available on your system path. 

```
npm install -g ts-node
```

Then install dependencies

```
npm ci
```
