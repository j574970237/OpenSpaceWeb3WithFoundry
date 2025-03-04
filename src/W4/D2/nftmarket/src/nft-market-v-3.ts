import {
  Cancel as CancelEvent,
  List as ListEvent,
  Sold as SoldEvent
} from "../generated/NFTMarketV3/NFTMarketV3"
import {
  Cancel,
  List,
  Sold,
  OrderBook,
  FilledOrder
} from "../generated/schema"

export function handleCancel(event: CancelEvent): void {
  let orderId = event.params.orderId
  let entity = new Cancel(orderId)

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  let filledOrder = new FilledOrder(orderId)
  filledOrder.blockNumber = event.block.number
  filledOrder.blockTimestamp = event.block.timestamp
  filledOrder.transactionHash = event.transaction.hash

  let orderBook = OrderBook.load(orderId);
  if (orderBook != null) {
    orderBook.cancelTxHash = event.transaction.hash
    orderBook.save()
    filledOrder.order = orderId
  }

  entity.save()
  filledOrder.save()
}

export function handleList(event: ListEvent): void {
  let entity = new List(event.params.orderId)
  entity.nft = event.params.nft
  entity.tokenId = event.params.tokenId
  entity.seller = event.params.seller
  entity.payToken = event.params.payToken
  entity.price = event.params.price
  entity.deadline = event.params.deadline

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  let orderBook = new OrderBook(event.params.orderId)
  orderBook.nft = event.params.nft
  orderBook.tokenId = event.params.tokenId
  orderBook.seller = event.params.seller
  orderBook.payToken = event.params.payToken
  orderBook.price = event.params.price
  orderBook.deadline = event.params.deadline
  
  orderBook.blockNumber = event.block.number
  orderBook.blockTimestamp = event.block.timestamp
  orderBook.transactionHash = event.transaction.hash

  entity.save()
  orderBook.save()
}

export function handleSold(event: SoldEvent): void {
  let orderId = event.params.orderId
  let entity = new Sold(orderId)
  entity.buyer = event.params.buyer
  entity.fee = event.params.fee

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  let filledOrder = new FilledOrder(orderId)
  filledOrder.buyer = event.params.buyer
  filledOrder.fee = event.params.fee

  filledOrder.blockNumber = event.block.number
  filledOrder.blockTimestamp = event.block.timestamp
  filledOrder.transactionHash = event.transaction.hash

  let orderBook = OrderBook.load(orderId);
  if (orderBook != null) {
    orderBook.filledTxHash = event.transaction.hash
    orderBook.save()
    filledOrder.order = orderId
  }

  entity.save()
  filledOrder.save()
}
