package main

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
)

// SimpleChaincode example simple Chaincode implementation
type DocnotaChaincode struct {
}

type document struct {
	Id      string  `json:"id"`
	Owner   []byte  `json:"owner"`
	Name    string  `json:"name"`
	State   string  `json:"state"`
	Doc     string  `json:"doc"`
}

// ===================================================================================
// Main
// ===================================================================================
func main() {
	err := shim.Start(new(DocnotaChaincode))
	if err != nil {
		fmt.Printf("Error starting Docnota chaincode: %s", err)
	}
}

// Init initializes chaincode
// ===========================
func (t *DocnotaChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	return shim.Success(nil)
}

// Invoke - Our entry point for Invocations
// ========================================
func (t *DocnotaChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()
	fmt.Println("invoke is running " + function)

	// Handle different functions
	if function == "createDoc" { //create a new document
		return t.createDoc(stub, args)
	} else if function == "getDoc" { //get a document
		return t.getDoc(stub, args)
	}

	fmt.Println("invoke did not find func: " + function) //error
	return shim.Error("Received unknown function invocation")
}

// ============================================================
// createDoc - create a new document, store into chaincode state
// ============================================================
func (t *DocnotaChaincode) createDoc(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var err error

	// 0 - Document id
	// 1 - Document name
	// 2 - JSON-encoded document
	if len(args) != 3 {
		return shim.Error("Incorrect number of arguments. Expecting 3 (id, name, doc)")
	}

	// ==== Input sanitation ====
	fmt.Println("- start - Create document")
	if len(args[0]) <= 0 {
		return shim.Error("1st argument must be a non-empty string")
	}
	if len(args[1]) <= 0 {
		return shim.Error("2nd argument must be a non-empty string")
	}
	if len(args[2]) <= 0 {
		return shim.Error("3rd argument must be a non-empty string")
	}
	_, err = strconv.Atoi(args[0])
	if err != nil {
		return shim.Error("1st argument must be a numeric string")
	}
	id := args[0]
	name := args[1]
	doc := args[2]
	
	// ==== Init non-input fields ====
	owner, err := stub.GetCreator()
	if err != nil {
		return shim.Error("Cannot get transaction creator's identity")
	}
	state := "created"

	// ==== Check if document with given id already exists ====
	documentAsBytes, err := stub.GetState(id)
	if err != nil {
		return shim.Error("Failed to get document: " + err.Error())
	} else if documentAsBytes != nil {
	    var d document
	    json.Unmarshal(documentAsBytes, &d)
    	errorMsg := fmt.Sprintf("Document with given id already exists.Id: %d, Name: %s ", d.Id, d.Name)
		fmt.Println(errorMsg)
		return shim.Error(errorMsg)
	}

	// ==== Create document object and marshal to JSON ====
	d := &document{id, owner, name, state, doc}
	documentAsBytes, err = json.Marshal(d)
	if err != nil {
		return shim.Error(err.Error())
	}

	// === Save document to state ===
	err = stub.PutState(id, documentAsBytes)
	if err != nil {
		return shim.Error(err.Error())
	}

	fmt.Println("- end - Create document")
	return shim.Success(nil)
}

// ===============================================
// getDoc - get a document from chaincode state
// ===============================================
func (t *DocnotaChaincode) getDoc(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	var jsonResp string
	var err error

	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting id of the document to query")
	}

	id := args[0]
	valAsbytes, err := stub.GetState(id) //get the marble from chaincode state
	if err != nil {
		jsonResp = "{\"error\":\"Failed to get state for document " + id + "\"}"
		return shim.Error(jsonResp)
	} else if valAsbytes == nil {
		jsonResp = "{\"error\":\"Document does not exist: " + id + "\"}"
		return shim.Error(jsonResp)
	}

	return shim.Success(valAsbytes)
}

