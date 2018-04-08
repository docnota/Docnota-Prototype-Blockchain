read -s -p "Enter peer password: " pswd

fabric-ca-client enroll -u http://$PEERNAME:$pswd@159.89.105.110:7054 -M $CORE_PEER_MSPCONFIGPATH

mkdir -p $CORE_PEER_MSPCONFIGPATH/admincerts
cp $CORE_PEER_MSPCONFIGPATH/signcerts/cert.pem $CORE_PEER_MSPCONFIGPATH/admincerts/

