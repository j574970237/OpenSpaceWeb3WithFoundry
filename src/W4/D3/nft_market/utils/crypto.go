package utils

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/sha256"
	"crypto/x509"
	"encoding/asn1"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"math/big"
	"strings"
)

// GenKeyPair 生成密钥对
func GenKeyPair() (privateKey string, publicKey string, e error) {
	priKey, e := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if e != nil {
		return "", "", e
	}
	ecPrivateKey, e := x509.MarshalECPrivateKey(priKey)
	if e != nil {
		return "", "", e
	}
	privateKey = base64.StdEncoding.EncodeToString(ecPrivateKey)

	X := priKey.X
	Y := priKey.Y
	xStr, e := X.MarshalText()
	if e != nil {
		return "", "", e
	}
	yStr, e := Y.MarshalText()
	if e != nil {
		return "", "", e
	}
	public := string(xStr) + "+" + string(yStr)
	publicKey = base64.StdEncoding.EncodeToString([]byte(public))
	return
}

// BuildPrivateKey 将base64编码的私钥转为PrivateKey
func BuildPrivateKey(privateKeyStr string) (priKey *ecdsa.PrivateKey, e error) {
	bytes, e := base64.StdEncoding.DecodeString(privateKeyStr)
	if e != nil {
		return nil, e
	}
	priKey, e = x509.ParseECPrivateKey(bytes)
	if e != nil {
		return nil, e
	}
	return
}

// BuildPublicKey 将base64编码的公钥转为PublicKey
func BuildPublicKey(publicKeyStr string) (pubKey *ecdsa.PublicKey, e error) {
	bytes, e := base64.StdEncoding.DecodeString(publicKeyStr)
	if e != nil {
		return nil, e
	}
	split := strings.Split(string(bytes), "+")
	xStr := split[0]
	yStr := split[1]
	x := new(big.Int)
	y := new(big.Int)
	e = x.UnmarshalText([]byte(xStr))
	if e != nil {
		return nil, e
	}
	e = y.UnmarshalText([]byte(yStr))
	if e != nil {
		return nil, e
	}
	pub := ecdsa.PublicKey{Curve: elliptic.P256(), X: x, Y: y}
	pubKey = &pub
	return
}

// Sign 使用ECDSA对给定内容进行签名。
func Sign(content string, privateKeyStr string) (signature string, err error) {
	priKey, err := BuildPrivateKey(privateKeyStr)
	if err != nil {
		return "", err
	}

	// 计算内容的SHA-256哈希值。
	hashedContent := hash(content)

	// 使用私钥对哈希值进行签名。
	r, s, err := ecdsa.Sign(rand.Reader, priKey, []byte(hashedContent))
	if err != nil {
		return "", err
	}

	// 将r和s按照ASN.1 DER编码格式合并。
	signatureBytes, err := encodeSignature(r, s)
	if err != nil {
		return "", err
	}

	// 将签名编码为十六进制字符串返回。
	signature = hex.EncodeToString(signatureBytes)
	return signature, nil
}

// VerifySign 公钥验签
func VerifySign(content string, signature string, publicKeyStr string) (bool, error) {
	decodeSign, err := hex.DecodeString(signature)
	if err != nil {
		return false, err
	}

	r, s, err := decodeSignature(decodeSign)
	if err != nil {
		return false, err
	}

	pubKey, err := BuildPublicKey(publicKeyStr)
	if err != nil {
		return false, err
	}

	hashedContent := hash(content)
	flag := ecdsa.Verify(pubKey, []byte(hashedContent), r, s)
	if flag {
		return flag, nil
	}
	return false, errors.New("failed to verify sign")
}

// hash sha256Hash算法
func hash(data string) string {
	hasher := sha256.New()
	hasher.Write([]byte(data))
	return base64.StdEncoding.EncodeToString(hasher.Sum(nil))
}

// encodeSignature 编码r和s为ASN.1 DER格式。
func encodeSignature(r, s *big.Int) ([]byte, error) {
	sig := struct {
		R, S *big.Int
	}{r, s}
	return asn1.Marshal(sig)
}

// decodeSignature 解析DER编码的签名数据，提取出r和s。
func decodeSignature(signature []byte) (r, s *big.Int, err error) {
	var asn1Signature struct {
		R, S *big.Int
	}
	_, err = asn1.Unmarshal(signature, &asn1Signature)
	if err != nil {
		return nil, nil, err
	}
	return asn1Signature.R, asn1Signature.S, nil
}
