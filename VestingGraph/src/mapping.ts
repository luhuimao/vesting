import { BigInt } from "@graphprotocol/graph-ts"
import {
  StreamV3,
  AllocateTokenId,
  CreateStream,
  RevokeAllocation,
  SenderWithdraw,
  WithdrawAllFromStream,
  WithdrawFromStreamByTokenId
} from "../generated/StreamV3/StreamV3"
import {
  AllocationsEntity, StreamEntity, RevokedAllocationsEntity,
  ClaimedAllEntity, ClaimedByTokenIdEntity, SenderWithdrawedEntity
} from "../generated/schema"

export function handleAllocateTokenId(event: AllocateTokenId): void {
  // Entities can be loaded from the store using a string ID; this ID
  // needs to be unique across all entities of the same type
  let entity = AllocationsEntity.load(event.transaction.from.toHex())

  // Entities only exist after they have been saved to the store;
  // `null` checks allow to create entities on demand
  if (!entity) {
    entity = new AllocationsEntity(event.transaction.from.toHex())

    // Entity fields can be set using simple assignments
    entity.count = BigInt.fromI32(0)
  }

  // BigInt and BigDecimal math are supported
  entity.count = entity.count.plus(BigInt.fromI32(1))

  // Entity fields can be set based on event parameters
  entity.streamId = event.params.streamId
  entity.startIndex = event.params.startIndex
  entity.allocateSize = event.params.allocateSize
  entity.nftShare = event.params.nftShare
  // Entities can be written to the store with `.save()`
  entity.save()

  // Note: If a handler doesn't require existing field values, it is faster
  // _not_ to load the entity from the store. Instead, create it fresh with
  // `new Entity(...)`, set the fields that should be updated and save the
  // entity back to the store. Fields that were not set or unset remain
  // unchanged, allowing for partial updates to be applied.

  // It is also possible to access smart contracts from mappings. For
  // example, the contract that has emitted the event can be connected to
  // with:
  //
  // let contract = Contract.bind(event.address)
  //
  // The following functions can then be called on this contract to access
  // state variables and other data:
  //
  // - contract.addNewEdition(...)
  // - contract.availableBalanceForTokenId(...)
  // - contract.checkIfRevoked(...)
  // - contract.createStream(...)
  // - contract.deltaOf(...)
  // - contract.erc721Address(...)
  // - contract.getAllAllocations(...)
  // - contract.getAllocationInfo(...)
  // - contract.getStreamInfo(...)
  // - contract.lastAllocation(...)
  // - contract.nextStreamId(...)
  // - contract.remainingBalanceByTokenId(...)
  // - contract.revokeStream(...)
  // - contract.senderWithdrawFromStream(...)
  // - contract.withdrawAllFromStream(...)
  // - contract.withdrawFromStreamByTokenId(...)
}

export function handleCreateStream(event: CreateStream): void {
  let entity = StreamEntity.load(event.transaction.from.toHex())

  if (!entity) {
    entity = new StreamEntity(event.transaction.from.toHex())

    entity.count = BigInt.fromI32(0)
  }

  entity.count = entity.count.plus(BigInt.fromI32(1))

  entity.streamId = event.params.streamId
  entity.sender = event.params.sender.toString()
  entity.tokenAddress = event.params.tokenAddress
  entity.startTime = event.params.startTime
  entity.stopTime = event.params.stopTime
  entity.erc721Address = event.params.erc721Address.toString()

  entity.save()
}

export function handleRevokeAllocation(event: RevokeAllocation): void {
  let entity = RevokedAllocationsEntity.load(event.transaction.from.toHex())

  if (!entity) {
    entity = new RevokedAllocationsEntity(event.transaction.from.toHex())

    entity.count = BigInt.fromI32(0)
  }

  entity.count = entity.count.plus(BigInt.fromI32(1))

  entity.streamId = event.params.streamId
  entity.startIndex = event.params.startIndex
  entity.revokeAmount = event.params.revokeAmount

  entity.save()
}

export function handleSenderWithdraw(event: SenderWithdraw): void {
  let entity = SenderWithdrawedEntity.load(event.transaction.from.toHex())

  if (!entity) {
    entity = new SenderWithdrawedEntity(event.transaction.from.toHex())

    entity.count = BigInt.fromI32(0)
  }

  entity.count = entity.count.plus(BigInt.fromI32(1))

  entity.streamId = event.params.streamId
  entity.amount = event.params.amount

  entity.save()
}

export function handleWithdrawAllFromStream(
  event: WithdrawAllFromStream
): void {
  let entity = ClaimedAllEntity.load(event.transaction.from.toHex())

  if (!entity) {
    entity = new ClaimedAllEntity(event.transaction.from.toHex())

    entity.count = BigInt.fromI32(0)
  }

  entity.count = entity.count.plus(BigInt.fromI32(1))

  entity.streamId = event.params.streamId
  entity.recipient = event.params.recipient.toString()
  entity.amount = event.params.amount

  entity.save()
}

export function handleWithdrawFromStreamByTokenId(
  event: WithdrawFromStreamByTokenId
): void {
  let entity = ClaimedByTokenIdEntity.load(event.transaction.from.toHex())

  if (!entity) {
    entity = new ClaimedByTokenIdEntity(event.transaction.from.toHex())

    entity.count = BigInt.fromI32(0)
  }

  entity.count = entity.count.plus(BigInt.fromI32(1))

  entity.streamId = event.params.streamId
  entity.recipient = event.params.recipient.toString()
  entity.tokenId = event.params.tokenId
  entity.amount = event.params.amount

  entity.save()
}
