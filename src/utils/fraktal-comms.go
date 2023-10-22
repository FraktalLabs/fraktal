package utils

import (
	"log"
	"math/big"
	"os"

	"github.com/ethereum/go-ethereum/accounts"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/accounts/keystore"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/ethclient"

	filestore "github.com/FraktalLabs/fraktal/contracts/go/predeploys/filestore"
)

func CreateTransactOpts(account accounts.Account, chainID *big.Int) (*bind.TransactOpts, error) {
  // Create a temporary keystore
  osHomeDir := os.Getenv("HOME")
  // Create transactor directory if it doesn't exist
  if _, err := os.Stat(osHomeDir + "/.transactor"); os.IsNotExist(err) {
    os.Mkdir(osHomeDir + "/.transactor", 0700)
  }

  keystore := keystore.NewKeyStore(osHomeDir + "/.transactor", keystore.StandardScryptN, keystore.StandardScryptP)
  // Read password from environment variable
  keystore.Unlock(account, os.Getenv("ACCOUNT_PASS"))
  return bind.NewKeyStoreTransactorWithChainID(keystore, account, chainID)
}

type FraktalTransactionConfig struct {
  GasLimit uint64
  GasPrice *big.Int
}

type FraktalContractAddressConfig struct {
  // Predeploys
  FilestoreAddress common.Address // 0x4200000000000000000000000000000000000000 for now
}

type FraktalContracts struct {
  FilestoreContract *filestore.Filestore
}

func CreateFraktalContractAddressConfig() FraktalContractAddressConfig {
  return FraktalContractAddressConfig{
    FilestoreAddress: common.HexToAddress("0x4200000000000000000000000000000000000000"),
  }
}

func CreateFraktalContracts(client *ethclient.Client, config FraktalContractAddressConfig) FraktalContracts {
  filestoreContract, err := filestore.NewFilestore(config.FilestoreAddress, client)
  if err != nil {
    log.Fatal(err)
  }

  return FraktalContracts{
    FilestoreContract: filestoreContract,
  }
}

type FraktalComms struct {
  RpcUrl string
  Client *ethclient.Client
  ChainID *big.Int
  TransactionConfig FraktalTransactionConfig

  ContractAddressConfig FraktalContractAddressConfig
  Contracts FraktalContracts
}

func NewFraktalComms(rpcUrl string, chainID *big.Int, transactionConfig FraktalTransactionConfig) (*FraktalComms, error) {
  client, err := ethclient.Dial(rpcUrl)
  if err != nil {
    return nil, err
  }

  contractAddressConfig := CreateFraktalContractAddressConfig()
  contracts := CreateFraktalContracts(client, contractAddressConfig)

  return &FraktalComms{
    RpcUrl: rpcUrl,
    Client: client,
    ChainID: chainID,
    TransactionConfig: transactionConfig,

    ContractAddressConfig: contractAddressConfig,
    Contracts: contracts,
  }, nil
}

func (comms *FraktalComms) CreateTransactionOpts(from common.Address, value *big.Int) (*bind.TransactOpts, error) {
  transactOpts, err := CreateTransactOpts(accounts.Account{Address: from}, comms.ChainID)
  if err != nil {
    return nil, err
  }
  transactOpts.GasLimit = comms.TransactionConfig.GasLimit
  transactOpts.GasPrice = comms.TransactionConfig.GasPrice
  transactOpts.Value = value

  return transactOpts, nil
}

func (comms *FraktalComms) ApproveFileHash(from common.Address, filename string, fileHash string) error {
  //TODO: check things here like existence, hash, ...
  transactOpts, err := comms.CreateTransactionOpts(from, big.NewInt(0))
  if err != nil {
    log.Println("Error creating transaction opts")
    return err
  }

  intHash := new(big.Int)
  intHash.SetString(fileHash, 16)
  tx, err := comms.Contracts.FilestoreContract.ApproveFile(transactOpts, filename, intHash)
  if err != nil {
    log.Println("Error approving file")
    return err
  }

  log.Println("ApproveFile tx sent: ", tx.Hash().Hex())
  return nil
}

func (comms *FraktalComms) AddFile(from common.Address, filename string) error {
  //TODO: check things here like existence, ...
  transactOpts, err := comms.CreateTransactionOpts(from, big.NewInt(0))
  if err != nil {
    log.Println("Error creating transaction opts")
    return err
  }

  tx, err := comms.Contracts.FilestoreContract.AddFile(transactOpts, filename)
  if err != nil {
    log.Println("Error adding file")
    return err
  }

  log.Println("AddFile tx sent: ", tx.Hash().Hex())
  return nil
}
