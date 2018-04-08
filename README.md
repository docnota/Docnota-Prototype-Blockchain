## Docnota Prototype
This is [Docnota](https://docnota.io/en/) Prototype peer node. You can use it to try a concept of future Docnota blockchain.

Network is powered by Hyperledger Fabric v1.0.5.

## Requirements
- Docker 17.06.2-ce or greater
- Docker Compose 1.14.0 or greater

## Getting Started
First you need to get enrollment certificate. Write to [protochain@docnota.io](mailto:protochain@docnota.io). Tell us about yourself or your company. In the subject line specify "Protototype Chain Access".

In response you'll get peer name and password for creating enrollment certificate.

Next, clone repo and use script to start node.
```
./start.sh
```
Peer node runs in the background. To stop use:
```
./stop.sh
```

## How to use
Start docker cli container.
```
./cli.sh
```
Get document by its `<id>`.
```
peer chaincode query -C docnota -n docnotacc -c '{"Args": ["getDoc", "<id>"]}'
```
Publish document with given `<id>` and `<name>`.
```
peer chaincode invoke -C docnota -n docnotacc -c '{"Args": ["createDoc", "<id>", "<name>", "<doc>"]}'
```
Where `<doc>` is JSON-encoded document. Example:
```
{
  "description": "Test document",
  "blocks": [
    {
      "block_id": 123,
      "name": "Hello world",
      "content": "Sample text"
    },
    {
      "block_id": 124,
      "name": "Hello world again",
      "content": "Sample text"
    },
    {
      "block_id": 2478,
      "name": "The End",
      "content": "Sample text"
    }
  ]
}
```
