// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package contract

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// NFTMarketMetaData contains all meta data concerning the NFTMarket contract.
var NFTMarketMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\"}],\"name\":\"SafeERC20FailedOperation\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"ETH_FLAG\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"buyer\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"seller\",\"type\":\"address\"},{\"internalType\":\"address\",\"name\":\"nft\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"tokenId\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"payToken\",\"type\":\"address\"},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\"}],\"name\":\"buyNFTForOffline\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"client\",\"type\":\"address\"}],\"name\":\"cancelWhiteListSigner\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"client\",\"type\":\"address\"}],\"name\":\"setWhiteList\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\"}],\"name\":\"whiteList\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"}]",
}

// NFTMarketABI is the input ABI used to generate the binding from.
// Deprecated: Use NFTMarketMetaData.ABI instead.
var NFTMarketABI = NFTMarketMetaData.ABI

// NFTMarket is an auto generated Go binding around an Ethereum contract.
type NFTMarket struct {
	NFTMarketCaller     // Read-only binding to the contract
	NFTMarketTransactor // Write-only binding to the contract
	NFTMarketFilterer   // Log filterer for contract events
}

// NFTMarketCaller is an auto generated read-only Go binding around an Ethereum contract.
type NFTMarketCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// NFTMarketTransactor is an auto generated write-only Go binding around an Ethereum contract.
type NFTMarketTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// NFTMarketFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type NFTMarketFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// NFTMarketSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type NFTMarketSession struct {
	Contract     *NFTMarket        // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// NFTMarketCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type NFTMarketCallerSession struct {
	Contract *NFTMarketCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts    // Call options to use throughout this session
}

// NFTMarketTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type NFTMarketTransactorSession struct {
	Contract     *NFTMarketTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts    // Transaction auth options to use throughout this session
}

// NFTMarketRaw is an auto generated low-level Go binding around an Ethereum contract.
type NFTMarketRaw struct {
	Contract *NFTMarket // Generic contract binding to access the raw methods on
}

// NFTMarketCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type NFTMarketCallerRaw struct {
	Contract *NFTMarketCaller // Generic read-only contract binding to access the raw methods on
}

// NFTMarketTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type NFTMarketTransactorRaw struct {
	Contract *NFTMarketTransactor // Generic write-only contract binding to access the raw methods on
}

// NewNFTMarket creates a new instance of NFTMarket, bound to a specific deployed contract.
func NewNFTMarket(address common.Address, backend bind.ContractBackend) (*NFTMarket, error) {
	contract, err := bindNFTMarket(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &NFTMarket{NFTMarketCaller: NFTMarketCaller{contract: contract}, NFTMarketTransactor: NFTMarketTransactor{contract: contract}, NFTMarketFilterer: NFTMarketFilterer{contract: contract}}, nil
}

// NewNFTMarketCaller creates a new read-only instance of NFTMarket, bound to a specific deployed contract.
func NewNFTMarketCaller(address common.Address, caller bind.ContractCaller) (*NFTMarketCaller, error) {
	contract, err := bindNFTMarket(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &NFTMarketCaller{contract: contract}, nil
}

// NewNFTMarketTransactor creates a new write-only instance of NFTMarket, bound to a specific deployed contract.
func NewNFTMarketTransactor(address common.Address, transactor bind.ContractTransactor) (*NFTMarketTransactor, error) {
	contract, err := bindNFTMarket(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &NFTMarketTransactor{contract: contract}, nil
}

// NewNFTMarketFilterer creates a new log filterer instance of NFTMarket, bound to a specific deployed contract.
func NewNFTMarketFilterer(address common.Address, filterer bind.ContractFilterer) (*NFTMarketFilterer, error) {
	contract, err := bindNFTMarket(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &NFTMarketFilterer{contract: contract}, nil
}

// bindNFTMarket binds a generic wrapper to an already deployed contract.
func bindNFTMarket(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := NFTMarketMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_NFTMarket *NFTMarketRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _NFTMarket.Contract.NFTMarketCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_NFTMarket *NFTMarketRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _NFTMarket.Contract.NFTMarketTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_NFTMarket *NFTMarketRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _NFTMarket.Contract.NFTMarketTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_NFTMarket *NFTMarketCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _NFTMarket.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_NFTMarket *NFTMarketTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _NFTMarket.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_NFTMarket *NFTMarketTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _NFTMarket.Contract.contract.Transact(opts, method, params...)
}

// ETHFLAG is a free data retrieval call binding the contract method 0x45fe280d.
//
// Solidity: function ETH_FLAG() view returns(address)
func (_NFTMarket *NFTMarketCaller) ETHFLAG(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _NFTMarket.contract.Call(opts, &out, "ETH_FLAG")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// ETHFLAG is a free data retrieval call binding the contract method 0x45fe280d.
//
// Solidity: function ETH_FLAG() view returns(address)
func (_NFTMarket *NFTMarketSession) ETHFLAG() (common.Address, error) {
	return _NFTMarket.Contract.ETHFLAG(&_NFTMarket.CallOpts)
}

// ETHFLAG is a free data retrieval call binding the contract method 0x45fe280d.
//
// Solidity: function ETH_FLAG() view returns(address)
func (_NFTMarket *NFTMarketCallerSession) ETHFLAG() (common.Address, error) {
	return _NFTMarket.Contract.ETHFLAG(&_NFTMarket.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_NFTMarket *NFTMarketCaller) Owner(opts *bind.CallOpts) (common.Address, error) {
	var out []interface{}
	err := _NFTMarket.contract.Call(opts, &out, "owner")

	if err != nil {
		return *new(common.Address), err
	}

	out0 := *abi.ConvertType(out[0], new(common.Address)).(*common.Address)

	return out0, err

}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_NFTMarket *NFTMarketSession) Owner() (common.Address, error) {
	return _NFTMarket.Contract.Owner(&_NFTMarket.CallOpts)
}

// Owner is a free data retrieval call binding the contract method 0x8da5cb5b.
//
// Solidity: function owner() view returns(address)
func (_NFTMarket *NFTMarketCallerSession) Owner() (common.Address, error) {
	return _NFTMarket.Contract.Owner(&_NFTMarket.CallOpts)
}

// WhiteList is a free data retrieval call binding the contract method 0x372c12b1.
//
// Solidity: function whiteList(address ) view returns(uint256)
func (_NFTMarket *NFTMarketCaller) WhiteList(opts *bind.CallOpts, arg0 common.Address) (*big.Int, error) {
	var out []interface{}
	err := _NFTMarket.contract.Call(opts, &out, "whiteList", arg0)

	if err != nil {
		return *new(*big.Int), err
	}

	out0 := *abi.ConvertType(out[0], new(*big.Int)).(**big.Int)

	return out0, err

}

// WhiteList is a free data retrieval call binding the contract method 0x372c12b1.
//
// Solidity: function whiteList(address ) view returns(uint256)
func (_NFTMarket *NFTMarketSession) WhiteList(arg0 common.Address) (*big.Int, error) {
	return _NFTMarket.Contract.WhiteList(&_NFTMarket.CallOpts, arg0)
}

// WhiteList is a free data retrieval call binding the contract method 0x372c12b1.
//
// Solidity: function whiteList(address ) view returns(uint256)
func (_NFTMarket *NFTMarketCallerSession) WhiteList(arg0 common.Address) (*big.Int, error) {
	return _NFTMarket.Contract.WhiteList(&_NFTMarket.CallOpts, arg0)
}

// BuyNFTForOffline is a paid mutator transaction binding the contract method 0xcb20252b.
//
// Solidity: function buyNFTForOffline(address buyer, address seller, address nft, uint256 tokenId, address payToken, uint256 price) payable returns()
func (_NFTMarket *NFTMarketTransactor) BuyNFTForOffline(opts *bind.TransactOpts, buyer common.Address, seller common.Address, nft common.Address, tokenId *big.Int, payToken common.Address, price *big.Int) (*types.Transaction, error) {
	return _NFTMarket.contract.Transact(opts, "buyNFTForOffline", buyer, seller, nft, tokenId, payToken, price)
}

// BuyNFTForOffline is a paid mutator transaction binding the contract method 0xcb20252b.
//
// Solidity: function buyNFTForOffline(address buyer, address seller, address nft, uint256 tokenId, address payToken, uint256 price) payable returns()
func (_NFTMarket *NFTMarketSession) BuyNFTForOffline(buyer common.Address, seller common.Address, nft common.Address, tokenId *big.Int, payToken common.Address, price *big.Int) (*types.Transaction, error) {
	return _NFTMarket.Contract.BuyNFTForOffline(&_NFTMarket.TransactOpts, buyer, seller, nft, tokenId, payToken, price)
}

// BuyNFTForOffline is a paid mutator transaction binding the contract method 0xcb20252b.
//
// Solidity: function buyNFTForOffline(address buyer, address seller, address nft, uint256 tokenId, address payToken, uint256 price) payable returns()
func (_NFTMarket *NFTMarketTransactorSession) BuyNFTForOffline(buyer common.Address, seller common.Address, nft common.Address, tokenId *big.Int, payToken common.Address, price *big.Int) (*types.Transaction, error) {
	return _NFTMarket.Contract.BuyNFTForOffline(&_NFTMarket.TransactOpts, buyer, seller, nft, tokenId, payToken, price)
}

// CancelWhiteListSigner is a paid mutator transaction binding the contract method 0x8db9385b.
//
// Solidity: function cancelWhiteListSigner(address client) returns()
func (_NFTMarket *NFTMarketTransactor) CancelWhiteListSigner(opts *bind.TransactOpts, client common.Address) (*types.Transaction, error) {
	return _NFTMarket.contract.Transact(opts, "cancelWhiteListSigner", client)
}

// CancelWhiteListSigner is a paid mutator transaction binding the contract method 0x8db9385b.
//
// Solidity: function cancelWhiteListSigner(address client) returns()
func (_NFTMarket *NFTMarketSession) CancelWhiteListSigner(client common.Address) (*types.Transaction, error) {
	return _NFTMarket.Contract.CancelWhiteListSigner(&_NFTMarket.TransactOpts, client)
}

// CancelWhiteListSigner is a paid mutator transaction binding the contract method 0x8db9385b.
//
// Solidity: function cancelWhiteListSigner(address client) returns()
func (_NFTMarket *NFTMarketTransactorSession) CancelWhiteListSigner(client common.Address) (*types.Transaction, error) {
	return _NFTMarket.Contract.CancelWhiteListSigner(&_NFTMarket.TransactOpts, client)
}

// SetWhiteList is a paid mutator transaction binding the contract method 0x39e899ee.
//
// Solidity: function setWhiteList(address client) returns()
func (_NFTMarket *NFTMarketTransactor) SetWhiteList(opts *bind.TransactOpts, client common.Address) (*types.Transaction, error) {
	return _NFTMarket.contract.Transact(opts, "setWhiteList", client)
}

// SetWhiteList is a paid mutator transaction binding the contract method 0x39e899ee.
//
// Solidity: function setWhiteList(address client) returns()
func (_NFTMarket *NFTMarketSession) SetWhiteList(client common.Address) (*types.Transaction, error) {
	return _NFTMarket.Contract.SetWhiteList(&_NFTMarket.TransactOpts, client)
}

// SetWhiteList is a paid mutator transaction binding the contract method 0x39e899ee.
//
// Solidity: function setWhiteList(address client) returns()
func (_NFTMarket *NFTMarketTransactorSession) SetWhiteList(client common.Address) (*types.Transaction, error) {
	return _NFTMarket.Contract.SetWhiteList(&_NFTMarket.TransactOpts, client)
}
