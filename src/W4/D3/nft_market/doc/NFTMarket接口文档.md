# OpenSpaceWeb3/W4D3/nft_market

## POST 上架订单

POST /market/create

> Body 请求参数

```json
{
  "privatekey": "MHcCAQEEIBcM1FvNRhOUPxEPLRrrlYRl41QDKGUB2xFSj8GN20R1oAoGCCqGSM49AwEHoUQDQgAEodjqRmgGdokoVITYzM11fEr0O+qr/rqjIHDoEm6O5C7/+QYh+IzgPrfVMtS4xXjcV4u8PNcUFatvdvxD1Jmhsg==",
  "publickey": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
  "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
  "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
  "token_id": 3,
  "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
  "price": 3000000000000000,
  "deadline": 1773136193
}
```

### 请求参数

| 名称           | 位置   | 类型      | 必选  | 中文名       | 说明   |
| ------------ | ---- | ------- | --- | --------- | ---- |
| body         | body | object  | 否   |           | none |
| » privatekey | body | string  | 是   | 私钥        | none |
| » publickey  | body | string  | 是   | 公钥        | none |
| » seller     | body | string  | 是   | 卖家地址      | none |
| » nft        | body | string  | 是   | NFT合约地址   | none |
| » token_id   | body | integer | 是   | NFT编号     | none |
| » pay_token  | body | string  | 是   | 支付代币的合约地址 | none |
| » price      | body | integer | 是   | 价格        | none |
| » deadline   | body | integer | 是   | 截止时间      | none |

> 返回示例

```json
{
  "order_id": 2,
  "SellOrder": {
    "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
    "token_id": 1,
    "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
    "price": 1000000000000000,
    "deadline": 1773136193
  },
  "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
  "signature": "3045022100ad248d0168be4dcc205d04df9a7b7121d5f33dbafcbaa1b80d5b52a70fa4729302203e5da9be32ea14d40edc831b1059ea7f9944c183681163dd1a690ef7a10a87b6",
  "filled_tx_hash": null,
  "block_number": null,
  "block_timestamp": null
}
```

### 返回结果

| 状态码 | 状态码含义                                                   | 说明   | 数据模型   |
| --- | ------------------------------------------------------- | ---- | ------ |
| 200 | [OK](https://tools.ietf.org/html/rfc7231#section-6.3.1) | none | Inline |

### 返回数据结构

状态码 **200**

| 名称                | 类型      | 必选   | 约束   | 中文名 | 说明   |
| ----------------- | ------- | ---- | ---- | --- | ---- |
| » order_id        | integer | true | none |     | none |
| » SellOrder       | object  | true | none |     | none |
| »» seller         | string  | true | none |     | none |
| »» nft            | string  | true | none |     | none |
| »» token_id       | integer | true | none |     | none |
| »» pay_token      | string  | true | none |     | none |
| »» price          | integer | true | none |     | none |
| »» deadline       | integer | true | none |     | none |
| » seller_pub_key  | string  | true | none |     | none |
| » signature       | string  | true | none |     | none |
| » filled_tx_hash  | string  | true | none |     | none |
| » block_number    | integer | true | none |     | none |
| » block_timestamp | integer | true | none |     | none |

## GET 获取密钥对

GET /keypair

> 返回示例

```json
{
  "private_key": "MHcCAQEEIBcM1FvNRhOUPxEPLRrrlYR......IHDoEm6O5C7/+QYh+IzgPrfVMtS4xXjcV4u8PNcUFatvdvxD1Jmhsg==",
  "public_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0"
}
```

### 返回结果

| 状态码 | 状态码含义                                                   | 说明   | 数据模型   |
| --- | ------------------------------------------------------- | ---- | ------ |
| 200 | [OK](https://tools.ietf.org/html/rfc7231#section-6.3.1) | none | Inline |

### 返回数据结构

## GET 展示已上架的NFT订单信息

GET /market/list

> 返回示例

```json
[
  {
    "order_id": 3,
    "SellOrder": {
      "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
      "token_id": 2,
      "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
      "price": 2000000000000000,
      "deadline": 1773136193
    },
    "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
    "signature": "304402200f50e255bd32cf22bbf7cfb88091ebc753927bc8f8ffe213ce21c6e14a226098022008fe78ba50b4f5b73173dd3788e5146d256820b82556d7f703e75df13421c55d",
    "filled_tx_hash": null,
    "block_number": null,
    "block_timestamp": null
  },
  {
    "order_id": 4,
    "SellOrder": {
      "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
      "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
      "token_id": 3,
      "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
      "price": 3000000000000000,
      "deadline": 1773136193
    },
    "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
    "signature": "304502205209353682dc87fa0827be25cf4860db83bb3c8811c2bcde5faa908808b80b65022100a39f9584300137f576dbcafcb6bb1c3363a618eda1fbe47a933bfdb290c99efd",
    "filled_tx_hash": null,
    "block_number": null,
    "block_timestamp": null
  }
]
```

### 返回结果

| 状态码 | 状态码含义                                                   | 说明   | 数据模型   |
| --- | ------------------------------------------------------- | ---- | ------ |
| 200 | [OK](https://tools.ietf.org/html/rfc7231#section-6.3.1) | none | Inline |

### 返回数据结构

状态码 **200**

| 名称                | 类型      | 必选   | 约束   | 中文名 | 说明   |
| ----------------- | ------- | ---- | ---- | --- | ---- |
| » order_id        | integer | true | none |     | none |
| » SellOrder       | object  | true | none |     | none |
| »» seller         | string  | true | none |     | none |
| »» nft            | string  | true | none |     | none |
| »» token_id       | integer | true | none |     | none |
| »» pay_token      | string  | true | none |     | none |
| »» price          | integer | true | none |     | none |
| »» deadline       | integer | true | none |     | none |
| » seller_pub_key  | string  | true | none |     | none |
| » signature       | string  | true | none |     | none |
| » filled_tx_hash  | null    | true | none |     | none |
| » block_number    | null    | true | none |     | none |
| » block_timestamp | null    | true | none |     | none |

## POST 购买NFT

POST /market/buy

> Body 请求参数

```json
{
  "buyer": "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
  "order_id": 3
}
```

### 请求参数

| 名称         | 位置   | 类型      | 必选  | 中文名  | 说明   |
| ---------- | ---- | ------- | --- | ---- | ---- |
| body       | body | object  | 否   |      | none |
| » buyer    | body | string  | 是   | 买家地址 | none |
| » order_id | body | integer | 是   | 订单id | none |

> 返回示例

```json
{
  "order_id": 2,
  "SellOrder": {
    "seller": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
    "nft": "0x7E27bCbe2F0eDdA3E0AA12492950a6B8703b00FB",
    "token_id": 1,
    "pay_token": "0x267fB71b280FB34B278CedE84180a9A9037C941b",
    "price": 1000000000000000,
    "deadline": 1773136193
  },
  "seller_pub_key": "NzMyMDU2MjQ0OTQ2OTQ1NzIzMDU3NzMyMDkzOTY0Nzg1Mjc5MzI2NDc5NjgwMDU0MDE4ODY4ODgwMDM3OTU5OTkwOTM4NjU1MDU4MzgrMTE1Nzc5NzYzNjM0MTk0NDY4ODMzNzM1OTUzMTg3NzQxNjY1MjUxMjI0NTI3NTM1NjA2NTA2MzI4NDE0MDkzNTIzMDQ0ODM3OTkwODM0",
  "signature": "3045022100ad248d0168be4dcc205d04df9a7b7121d5f33dbafcbaa1b80d5b52a70fa4729302203e5da9be32ea14d40edc831b1059ea7f9944c183681163dd1a690ef7a10a87b6",
  "filled_tx_hash": "0x5ecfb746f7fee86a512bda3bd62ab7a38cb4c744240a92abef3659146b0a6d78",
  "block_number": 22008143,
  "block_timestamp": 1741609950
}
```

### 返回结果

| 状态码 | 状态码含义                                                   | 说明   | 数据模型   |
| --- | ------------------------------------------------------- | ---- | ------ |
| 200 | [OK](https://tools.ietf.org/html/rfc7231#section-6.3.1) | none | Inline |

### 返回数据结构

状态码 **200**

| 名称                | 类型      | 必选   | 约束   | 中文名 | 说明   |
| ----------------- | ------- | ---- | ---- | --- | ---- |
| » order_id        | integer | true | none |     | none |
| » SellOrder       | object  | true | none |     | none |
| »» seller         | string  | true | none |     | none |
| »» nft            | string  | true | none |     | none |
| »» token_id       | integer | true | none |     | none |
| »» pay_token      | string  | true | none |     | none |
| »» price          | integer | true | none |     | none |
| »» deadline       | integer | true | none |     | none |
| » seller_pub_key  | string  | true | none |     | none |
| » signature       | string  | true | none |     | none |
| » filled_tx_hash  | string  | true | none |     | none |
| » block_number    | integer | true | none |     | none |
| » block_timestamp | integer | true | none |     | none |


