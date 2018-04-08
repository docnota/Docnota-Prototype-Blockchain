#!/bin/bash

function main {
    pullImages
    if [ ! -f docker-compose-peer.yml ]; then
        genCompose
    fi
    
    if [ ! -f data/msp/signcerts/cert.pem ]; then
        docker-compose -f docker-compose-reg.yml run --rm tools
    fi
    docker-compose -f docker-compose-peer.yml up -d
    if [ ! -f store/chaincodes/docnotaccx.0.1 ] || [ ! -d store/ledgersData/chains/chains/docnota ]; then
        docker-compose -f docker-compose-setup.yml run --rm tools
    fi
}

function pullImages {
    FABRIC_TAG="`uname -m`"

    echo "===> Pulling fabric Images"
    echo "==> FABRIC IMAGE: peer"
    echo
    docker pull hyperledger/fabric-peer:$FABRIC_TAG-1.0.5
    docker tag hyperledger/fabric-peer:$FABRIC_TAG-1.0.5 hyperledger/fabric-peer
    echo "==> FABRIC IMAGE: ca-tools"
    echo
    docker pull hyperledger/fabric-ca-tools:$FABRIC_TAG-1.1.0-alpha
    docker tag hyperledger/fabric-ca-tools:$FABRIC_TAG-1.1.0-alpha hyperledger/fabric-ca-tools
}

function genCompose {
    read -p "Enter peer name: " PEERNAME
    {
    echo "version: '2'

networks:
  docnota:

services:

  tools:
    container_name: tools
    image: hyperledger/fabric-ca-tools
    tty: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_LOGGING_LEVEL=DEBUG
      - CORE_PEER_ID=cli
      - CORE_PEER_ADDRESS=pubpeer.docnota.com:7051
      - CORE_PEER_LOCALMSPID=DocnotaMSP
      - CORE_PEER_TLS_ENABLED=false
      - CORE_PEER_MSPCONFIGPATH=/data/msp
      - FABRIC_CA_HOME=/data/msp
      - PEERNAME=$PEERNAME
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash -c 'sleep 5; /scripts/reg.sh'
    volumes:
        - /var/run/:/host/var/run/
        - ./data:/data
        - ./scripts:/scripts
        - ./chaincode:/opt/gopath/src/docnota.com/chaincode
    networks:
      - docnota
"
      } > docker-compose-reg.yml
      {
    echo "version: '2'

networks:
  docnota:

services:

  pubpeer.docnota.com:
    container_name: pubpeer.docnota.com
    image: hyperledger/fabric-peer
    logging:
      driver: \"json-file\"
      options:
        max-size: \"10m\"
        max-file: \"5\"
    environment:
      - CORE_PEER_ID=$PEERNAME
      - CORE_PEER_ADDRESS=127.0.0.1:7051
      - CORE_PEER_CHAINCODELISTENADDRESS=pubpeer.docnota.com:7052
      - CORE_PEER_LOCALMSPID=DocnotaMSP
      - CORE_PEER_MSPCONFIGPATH=/data/msp
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=protopeer_docnota
      - CORE_PEER_TLS_ENABLED=false
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_GOSSIP_USELEADERELECTION=true
      - CORE_PEER_GOSSIP_ORGLEADER=false
      - CORE_PEER_GOSSIP_SKIPHANDSHAKE=true
      - ORG=docnota
      - ORG_ADMIN_CERT=/data/docnota/msp/admincerts/cert.pem
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash -c 'peer node start'
    volumes:
      - ./data:/data
      - ./scripts:/scripts
      - ./chaincode:/opt/gopath/src/docnota.com/chaincode
      - ./store:/var/hyperledger/production
      - /var/run:/host/var/run
    ports:
      - \"7051:7051\"
      - \"7053:7053\"
    networks:
      - docnota"
      } > docker-compose-peer.yml
}

main
