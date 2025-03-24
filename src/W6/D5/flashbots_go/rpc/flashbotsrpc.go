package rpc

import (
	"bytes"
	"crypto/ecdsa"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/ethereum/go-ethereum/accounts"
	"github.com/ethereum/go-ethereum/common/hexutil"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
)

// New create new rpc client with given url
func New(url string, options ...func(rpc *FlashbotsRPC)) *FlashbotsRPC {
	rpc := &FlashbotsRPC{
		url:     url,
		log:     log.New(os.Stderr, "", log.LstdFlags),
		Headers: make(map[string]string),
		Timeout: 30 * time.Second,
	}

	rpc.client = &http.Client{
		Timeout: rpc.Timeout,
	}
	// this way if client is set explicitly it overwrites timeout preferences set above
	for _, option := range options {
		option(rpc)
	}
	return rpc
}

// NewFlashbotsRPC create new rpc client with given url
func NewFlashbotsRPC(url string, options ...func(rpc *FlashbotsRPC)) *FlashbotsRPC {
	return New(url, options...)
}

func (rpc *FlashbotsRPC) call(method string, target interface{}, params ...interface{}) error {
	result, err := rpc.Call(method, params...)
	if err != nil {
		return err
	}

	if target == nil {
		return nil
	}

	return json.Unmarshal(result, target)
}

// URL returns client url
func (rpc *FlashbotsRPC) URL() string {
	return rpc.url
}

// Call returns raw response of method call
func (rpc *FlashbotsRPC) Call(method string, params ...interface{}) (json.RawMessage, error) {
	request := rpcRequest{
		ID:      1,
		JSONRPC: "2.0",
		Method:  method,
		Params:  params,
	}

	body, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", rpc.url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Accept", "application/json")
	for k, v := range rpc.Headers {
		req.Header.Add(k, v)
	}

	response, err := rpc.client.Do(req)
	if response != nil {
		defer response.Body.Close()
	}
	if err != nil {
		return nil, err
	}

	data, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}

	if rpc.Debug {
		rpc.log.Println(fmt.Sprintf("%s\nRequest: %s\nResponse: %s\n", method, body, data))
	}

	resp := new(rpcResponse)
	if err := json.Unmarshal(data, resp); err != nil {
		return nil, err
	}

	if resp.Error != nil {
		return nil, *resp.Error
	}

	return resp.Result, nil
}

// CallWithFlashbotsSignature is like Call but also signs the request
func (rpc *FlashbotsRPC) CallWithFlashbotsSignature(method string, privKey *ecdsa.PrivateKey, params ...interface{}) (json.RawMessage, error) {
	request := rpcRequest{
		ID:      1,
		JSONRPC: "2.0",
		Method:  method,
		Params:  params,
	}

	body, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}

	hashedBody := hexutil.Encode(crypto.Keccak256(body))
	sig, err := crypto.Sign(accounts.TextHash([]byte(hashedBody)), privKey)
	if err != nil {
		return nil, err
	}

	signature := crypto.PubkeyToAddress(privKey.PublicKey).Hex() + ":" + hexutil.Encode(sig)

	req, err := http.NewRequest("POST", rpc.url, bytes.NewBuffer(body))
	if err != nil {
		return nil, err
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Accept", "application/json")
	req.Header.Add("X-Flashbots-Signature", signature)
	for k, v := range rpc.Headers {
		req.Header.Add(k, v)
	}

	response, err := rpc.client.Do(req)
	if response != nil {
		defer response.Body.Close()
	}
	if err != nil {
		return nil, err
	}

	data, err := io.ReadAll(response.Body)
	if err != nil {
		return nil, err
	}

	if rpc.Debug {
		rpc.log.Println(fmt.Sprintf("%s\nRequest: %s\nSignature: %s\nResponse: %s\n", method, body, signature, data))
	}

	// On error, response looks like this instead of JSON-RPC: {"error":"block param must be a hex int"}
	errorResp := new(RelayErrorResponse)
	if err := json.Unmarshal(data, errorResp); err == nil && errorResp.Error != "" {
		// relay returned an error
		return nil, fmt.Errorf("%w: %s", ErrRelayErrorResponse, errorResp.Error)
	}

	resp := new(rpcResponse)
	if err := json.Unmarshal(data, resp); err != nil {
		return nil, err
	}

	if resp.ID != request.ID || resp.JSONRPC != request.JSONRPC {
		// this means we got back JSON but not a valid JSONRPC response
		return nil, fmt.Errorf("%w: invalid JSONRPC response (HTTP status code: %d)", ErrRelayErrorResponse, response.StatusCode)
	}

	if resp.Error != nil {
		return nil, fmt.Errorf("%w: %s", ErrRelayErrorResponse, (*resp).Error.Message)
	}

	return resp.Result, nil
}

func (rpc *FlashbotsRPC) FlashbotsSendBundle(privKey *ecdsa.PrivateKey, param FlashbotsSendBundleRequest) (res FlashbotsSendBundleResponse, err error) {
	rawMsg, err := rpc.CallWithFlashbotsSignature("eth_sendBundle", privKey, param)
	if err != nil {
		return res, err
	}
	err = json.Unmarshal(rawMsg, &res)
	return res, err
}

func (rpc *FlashbotsRPC) FlashbotsGetBundleStatsV2(privKey *ecdsa.PrivateKey, param FlashbotsGetBundleStatsParam) (res FlashbotsGetBundleStatsResponseV2, err error) {
	rawMsg, err := rpc.CallWithFlashbotsSignature("flashbots_getBundleStatsV2", privKey, param)
	if err != nil {
		return res, err
	}
	err = json.Unmarshal(rawMsg, &res)
	return res, err
}

// EthBlockNumber returns the number of most recent block.
func (rpc *FlashbotsRPC) EthBlockNumber(privKey *ecdsa.PrivateKey) (blockNumber int, err error) {
	rawMsg, err := rpc.CallWithFlashbotsSignature("eth_blockNumber", privKey)
	if err != nil {
		return 0, err
	}
	err = json.Unmarshal(rawMsg, &blockNumber)
	return blockNumber, err
}

func IntToHex(i int) string {
	return fmt.Sprintf("0x%x", i)
}

func TxToRlp(tx *types.Transaction) string {
	var buff bytes.Buffer
	tx.EncodeRLP(&buff)
	return fmt.Sprintf("%x", buff.Bytes())
}

func ParseInt(value string) (int, error) {
	i, err := strconv.ParseInt(strings.TrimPrefix(value, "0x"), 16, 64)
	if err != nil {
		return 0, err
	}

	return int(i), nil
}
