package rpc

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"time"
)

// ErrRelayErrorResponse means it's a standard Flashbots relay error response - probably a user error rather than JSON or network error
var ErrRelayErrorResponse = errors.New("relay error response")

type RelayErrorResponse struct {
	Error string `json:"error"`
}

// RpcError - ethereum error
type RpcError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (err RpcError) Error() string {
	return fmt.Sprintf("Error %d (%s)", err.Code, err.Message)
}

type rpcResponse struct {
	ID      int             `json:"id"`
	JSONRPC string          `json:"jsonrpc"`
	Result  json.RawMessage `json:"result"`
	Error   *RpcError       `json:"error"`
}

type rpcRequest struct {
	ID      int           `json:"id"`
	JSONRPC string        `json:"jsonrpc"`
	Method  string        `json:"method"`
	Params  []interface{} `json:"params"`
}

type httpClient interface {
	Post(url string, contentType string, body io.Reader) (*http.Response, error)
	Do(req *http.Request) (*http.Response, error)
}

// FlashbotsRPC - Ethereum rpc client
type FlashbotsRPC struct {
	url     string
	client  httpClient
	log     logger
	Debug   bool
	Headers map[string]string // Additional headers to send with the request
	Timeout time.Duration
}

type logger interface {
	Println(v ...interface{})
}

// sendBundle
type FlashbotsSendBundleRequest struct {
	Txs          []string  `json:"txs"`                         // Array[String], A list of signed transactions to execute in an atomic bundle
	BlockNumber  string    `json:"blockNumber"`                 // String, a hex encoded block number for which this bundle is valid on
	MinTimestamp *uint64   `json:"minTimestamp,omitempty"`      // (Optional) Number, the minimum timestamp for which this bundle is valid, in seconds since the unix epoch
	MaxTimestamp *uint64   `json:"maxTimestamp,omitempty"`      // (Optional) Number, the maximum timestamp for which this bundle is valid, in seconds since the unix epoch
	RevertingTxs *[]string `json:"revertingTxHashes,omitempty"` // (Optional) Array[String], A list of tx hashes that are allowed to revert
}

type FlashbotsSendBundleResponse struct {
	BundleHash string `json:"bundleHash"`
}

type FlashbotsGetBundleStatsParam struct {
	BlockNumber string `json:"blockNumber"` // String, a hex encoded block number for which this bundle is valid on
	BundleHash  string `json:"bundleHash"`  // String, returned by the flashbots api when calling eth_sendBundle
}

type FlashbotsGetBundleStatsResponseV2 struct {
	IsSimulated            bool                          `json:"isSimulated"`
	IsHighPriority         bool                          `json:"isHighPriority"`
	SimulatedAt            time.Time                     `json:"simulatedAt"`
	ReceivedAt             time.Time                     `json:"receivedAt"`
	ConsideredByBuildersAt []*BuilderPubkeyWithTimestamp `json:"consideredByBuildersAt"`
	SealedByBuildersAt     []*BuilderPubkeyWithTimestamp `json:"sealedByBuildersAt"`
}

type BuilderPubkeyWithTimestamp struct {
	Pubkey    string    `json:"pubkey"`
	Timestamp time.Time `json:"timestamp"`
}
