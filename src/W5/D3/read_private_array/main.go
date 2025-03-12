package main

import (
	"context"
	"encoding/binary"
	"fmt"
	"log"
	"math/big"

	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
)

func main() {
	client, err := ethclient.Dial("http://127.0.0.1:8545") // 连接本地网络
	if err != nil {
		log.Fatalf("Failed to connect to the Ethereum client: %v", err)
	}

	contractAddress := common.HexToAddress("0x71d75C9A9e1a4fFa5a16556b51D6e630A4FA902A") // esRNT合约在本地网络中的地址
	// 已知locks存在slot 0，计算locks数组起始startIndex
	startIndex := crypto.Keccak256(encodeSlot(uint64(0)))
	for i := 0; i < 11; i++ {
		user, startTime, amount := readLockInfo(client, contractAddress, incrementIndex(startIndex, int64(2*i))) // 每个LockInfo会占用2个slot
		fmt.Printf("locks[%d]: user: %s, startTime: %d, amount: %s\n", i, user, startTime, amount)
	}
}

// 根据LockInfo结构体特点，我们可以知道user和startTime会共用一个slot，amount单独占用一个slot
func readLockInfo(client *ethclient.Client, contractAddress common.Address, index []byte) (string, int64, string) {
	// 调用eth_getStorageAt api查询user和startTime的slot
	data1, _ := client.StorageAt(context.Background(), contractAddress, common.BytesToHash(index), nil)
	addr := common.BytesToAddress(data1[12:]) // 后 20 字节为 address user
	startTime := data1[4:12]                  // 第4-12这8字节为 uint64 startTime
	time := binary.BigEndian.Uint64(startTime)
	// 查询amount的slot，为ser和startTime的slot+1
	data2, _ := client.StorageAt(context.Background(), contractAddress, common.BytesToHash(incrementIndex(index, 1)), nil)
	amount := new(big.Int).SetBytes(data2)
	return addr.Hex(), int64(time), amount.String()
}

func encodeSlot(slot uint64) []byte {
	encoded := make([]byte, 32)                    // 32 字节的零填充数组
	binary.BigEndian.PutUint64(encoded[24:], slot) // 后8字节存储 slot 值
	return encoded
}

// incrementIndex 在indexBytes基础上加i
func incrementIndex(indexBytes []byte, i int64) []byte {
	indexInt := new(big.Int).SetBytes(indexBytes)
	indexInt.Add(indexInt, big.NewInt(i))

	paddedBytes := make([]byte, 32)
	indexInt.FillBytes(paddedBytes) // 自动填充到32字节

	return paddedBytes
}
