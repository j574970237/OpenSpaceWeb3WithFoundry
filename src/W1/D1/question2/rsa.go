package main

import (
    "crypto/rand"
    "crypto/rsa"
    "crypto/sha256"
    "crypto"
    "encoding/hex"
    "fmt"
    "strings"
    "time"
)

/**
题目：
实践非对称加密 RSA（编程语言不限）：
1. 先生成一个公私钥对
2. 用私钥对符合 POW 4 个 0 开头的哈希值的 “昵称 + nonce” 进行私钥签名
3. 用公钥验证
**/
func main() {
    // 生成 RSA 公私钥对
    privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
    if err != nil {
        fmt.Println("生成私钥失败:", err)
        return
    }
    publicKey := &privateKey.PublicKey

    // 定义昵称和初始 nonce
    nickname := "JackZhu"
    nonce := 0
    targetPrefix4 := "0000"

    // 寻找满足4个0开头的哈希值
    startTime := time.Now()
    var hashStr string
    for {
        hash := sha256.Sum256([]byte(fmt.Sprintf("%s%d", nickname, nonce)))
        hashStr = hex.EncodeToString(hash[:])
        if strings.HasPrefix(hashStr, targetPrefix4) {
            spendTime := time.Since(startTime)
            fmt.Printf("寻找满足4个0开头的哈希值:\n")
            fmt.Printf("花费的时间: %s\n", spendTime)
            fmt.Printf("Hash的内容: %s%d\n", nickname, nonce)
            fmt.Printf("Hash值: %s\n", hashStr)
            break
        }
        nonce++
    }

    // 使用私钥对哈希值进行签名
    hash := sha256.Sum256([]byte(fmt.Sprintf("%s%d", nickname, nonce)))
    signature, err := rsa.SignPKCS1v15(rand.Reader, privateKey, crypto.SHA256, hash[:])
    if err != nil {
        fmt.Println("签名失败:", err)
        return
    }
    fmt.Printf("签名: %x\n", signature)

    // 使用公钥验证签名
    err = rsa.VerifyPKCS1v15(publicKey, crypto.SHA256, hash[:], signature)
    if err != nil {
        fmt.Println("验证签名失败:", err)
    } else {
        fmt.Println("验证签名成功")
    }
}