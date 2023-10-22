// Cmdline to use fraktal node filestore

package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"math/big"
	"net/http"
	"os"
	"path/filepath"
	"time"

	utils "github.com/FraktalLabs/fraktal/src/utils"
	"github.com/ethereum/go-ethereum/common"
)

func main() { os.Exit(mainImpl()) }

func ApproveFile(nodeComms *utils.FraktalComms, address common.Address, file string, fileHash string) error {
  err := nodeComms.ApproveFileHash(address, file, fileHash)
  if err != nil {
    return err
  }

  log.Println("Sent approve file tx")
  // TODO: Wait for tx to be mined, for now just sleep
  time.Sleep(2 * time.Second)

  // Check file hash
  hashInt, err := nodeComms.Contracts.FilestoreContract.GetFileHash(nil, address, file)
  if err != nil {
    return err
  }

  // hashStr is hex string of hashInt
  hashStr := hashInt.Text(16)

  if hashStr != fileHash {
    log.Println("File hash mismatch : ", hashStr, fileHash)
    return err
  }

  log.Println("File approved w/ hash : ", hashStr)

  return nil
}

func AddFile(nodeComms *utils.FraktalComms, address common.Address, file string) error {
  err := nodeComms.AddFile(address, file)
  if err != nil {
    return err
  }

  log.Println("Sent add file tx")
  // TODO: Wait for tx to be mined, for now just sleep
  time.Sleep(2 * time.Second)

  // TODO: Check file in filestore list

  return nil
}

type Server struct {
  nodeComms *utils.FraktalComms
  port string
  dataDir string
}

var server Server

type FilePayload struct {
  Address string
  FilePath string
}

func (server *Server) uploadFile(w http.ResponseWriter, r *http.Request) {
    if r.Method != http.MethodPost {
        http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
        return
    }
  
    // Parse the multipart form data with a maximum upload size of 10 MB
    r.ParseMultipartForm(10 << 20) // 10 MB
      
    // Get the file from the request
    //file, handler, err := r.FormFile("file")
    file, _, err := r.FormFile("file")
    if err != nil {
        http.Error(w, "Error parsing file", http.StatusBadRequest)
        return   
    }
    defer file.Close()

    // Get payload as json string
    payload := r.FormValue("payload_json")
    if payload == "" {
      http.Error(w, "Error parsing payload form", http.StatusBadRequest)
      return
    }

    // Interpret payload as json
    var filePayload FilePayload
    err = json.Unmarshal([]byte(payload), &filePayload)
    if err != nil {
      http.Error(w, "Error parsing payload json", http.StatusBadRequest)
      return
    }

    // Check if file is approved
    expectedHash, err := server.nodeComms.Contracts.FilestoreContract.GetFileHash(nil, common.HexToAddress(filePayload.Address), filePayload.FilePath)
    if err != nil {
      http.Error(w, "Error getting file hash", http.StatusInternalServerError)
      return
    }

    h := sha256.New()
    if _, err := io.Copy(h, file); err != nil {
      http.Error(w, "Error copying file data", http.StatusInternalServerError)
      return
    }
    hash := h.Sum(nil)
    hashStr := hex.EncodeToString(hash)

    if expectedHash.Text(16) != hashStr {
      http.Error(w, "File not approved", http.StatusUnauthorized)
      return
    }

    file.Seek(0, 0)
    
    // Create a directory to store uploaded files if it doesn't exist
    fileStoreDir := server.dataDir + "/filestore/"
    if _, err := os.Stat(fileStoreDir); os.IsNotExist(err) {  
        err := os.Mkdir(fileStoreDir, 0755)    
        if err != nil {  
            http.Error(w, "Error creating upload directory", http.StatusInternalServerError)  
            return  
        }  
    }

    uploadDir := fileStoreDir + filePayload.Address
    if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
        err := os.Mkdir(uploadDir, 0755)
        if err != nil { 
            http.Error(w, "Error creating upload directory", http.StatusInternalServerError)
            return
        }
    }
  
    //fileName := handler.Filename
    fileName := filePayload.FilePath
    filePath := filepath.Join(uploadDir, fileName)
    
    // Create the new file
    newFile, err := os.Create(filePath)
    if err != nil {
        http.Error(w, "Error creating the file", http.StatusInternalServerError)
        return
    }
    defer newFile.Close()

    // Copy the uploaded file data into the new file
    _, err = io.Copy(newFile, file) 
    if err != nil {
        http.Error(w, "Error copying file data", http.StatusInternalServerError)
        return
    }

    fmt.Fprintf(w, "File uploaded successfully: %s  w/ hash %s\n", fileName, hashStr)
    //log.Println("File uploaded successfully: ", fileName, "w/ hash : ", hashStr)
    log.Println("File uploaded successfully: ", fileName)

    // Use the following curl command to test the endpoint:
    // curl -F "file=@tests/test.txt" http://localhost:8542/upload
}

func Serve(nodeComms *utils.FraktalComms, port string, dataDir string) error {
  server = Server{
    nodeComms: nodeComms,
    port: port,
    dataDir: dataDir,
  }

  log.Println("Starting filestore server on port : ", port)

  http.HandleFunc("/upload", server.uploadFile)
  http.ListenAndServe(":" + port, nil)

  return nil
}

func mainImpl() int {
  approveCmd := flag.NewFlagSet("approve", flag.ExitOnError)
  addCmd := flag.NewFlagSet("add", flag.ExitOnError)
  serveCmd := flag.NewFlagSet("serve", flag.ExitOnError)

  if len(os.Args) < 2 {
    flag.Usage()
    return 1
  }

  switch os.Args[1] {
  case "approve":
    address := approveCmd.String("address", "", "address to bridge with")
    file := approveCmd.String("file", "", "file to upload")
    fileHash := approveCmd.String("fileHash", "", "file hash to approve") // TODO: Calculate hash
    rpc := approveCmd.String("rpc", "http://localhost:8545", "rpc address")
    approveCmd.Parse(os.Args[2:])

    if *address == "" || *file == "" || *fileHash == "" {
      flag.Usage()
      return 1
    }

    //TODO: Hardcoded chainid
    nodeComms, err := utils.NewFraktalComms(*rpc, big.NewInt(int64(505)), utils.FraktalTransactionConfig{
      GasLimit: 30000000,
      GasPrice: big.NewInt(200),
    })
    if err != nil {
      log.Println(err)
      return 1
    }

    err = ApproveFile(nodeComms, common.HexToAddress(*address), *file, *fileHash)
    if err != nil {
      log.Println(err)
      return 1
    }
  case "add":
    address := addCmd.String("address", "", "address to bridge with")
    file := addCmd.String("file", "", "file to upload")
    rpc := addCmd.String("rpc", "http://localhost:8545", "rpc address")
    addCmd.Parse(os.Args[2:])

    if *address == "" || *file == "" {
      flag.Usage()
      return 1
    }

    nodeComms, err := utils.NewFraktalComms(*rpc, big.NewInt(int64(505)), utils.FraktalTransactionConfig{
      GasLimit: 30000000,
      GasPrice: big.NewInt(200),
    })
    if err != nil {
      log.Println(err)
      return 1
    }

    err = AddFile(nodeComms, common.HexToAddress(*address), *file)
    if err != nil {
      log.Println(err)
      return 1
    }
  case "serve":
    port := serveCmd.String("port", "8542", "port to serve on")
    rpc := serveCmd.String("rpc", "http://localhost:8545", "rpc address")
    dataDir := serveCmd.String("dataDir", "", "data directory")
    serveCmd.Parse(os.Args[2:])

    if *dataDir == "" {
      flag.Usage()
      return 1
    }

    nodeComms, err := utils.NewFraktalComms(*rpc, big.NewInt(int64(505)), utils.FraktalTransactionConfig{
      GasLimit: 30000000,
      GasPrice: big.NewInt(200),
    })
    if err != nil {
      log.Println(err)
      return 1
    }

    err = Serve(nodeComms, *port, *dataDir)
    if err != nil {
      log.Println(err)
      return 1
    }
  default:
    flag.Usage()
    return 1
  }

  return 0
}
