import {
  ethereum,
  Bytes,
  BigInt,
  crypto,
  ethereum,
  log,
  store,
} from "@graphprotocol/graph-ts";
import {
  FlowSplitter,
  PoolCreated,
  PoolMetadataUpdated,
  RoleGranted,
  RoleRevoked,
} from "../generated/FlowSplitter/FlowSplitter";
import {
  Pool,
  PoolAdmin,
  PoolMetadataUpdatedEvent,
  PoolAdminAddedEvent,
  PoolAdminRemovedEvent,
} from "../generated/schema";

export function handlePoolCreated(event: PoolCreated): void {
  const pool = new Pool(event.params.poolId.toHex());
  const adminRole = Bytes.fromByteArray(
    crypto.keccak256(
      ethereum
        .encode(ethereum.Value.fromUnsignedBigInt(event.params.poolId))!
        .concat(Bytes.fromUTF8("admin"))
    )
  );
  const contract = FlowSplitter.bind(event.address);
  const callResultName = contract.try_getPoolNameById(event.params.poolId);
  const callResultSymbol = contract.try_getPoolSymbolById(event.params.poolId);
  const poolName = callResultName.reverted
    ? "Superfluid Pool"
    : callResultName.value;
  const poolSymbol = callResultSymbol.reverted
    ? "POOL"
    : callResultSymbol.value;

  pool.poolAddress = event.params.poolAddress;
  pool.name = poolName;
  pool.symbol = poolSymbol;
  pool.token = event.params.token;
  pool.metadata = event.params.metadata;
  pool.adminRole = adminRole;
  pool.createdAtBlock = event.block.number;
  pool.createdAtTimestamp = event.block.timestamp;

  pool.save();
}

export function handlePoolMetadataUpdated(event: PoolMetadataUpdated): void {
  const pool = new Pool(event.params.poolId.toHex());

  pool.metadata = event.params.metadata;

  pool.save();

  const poolMetadataUpdatedEvent = new PoolMetadataUpdatedEvent(
    `PoolMetadataUpdatedEvent-${event.transaction.hash.toHexString()}-${event.logIndex.toString()}`
  );

  poolMetadataUpdatedEvent.metadata = event.params.metadata;
  poolMetadataUpdatedEvent.pool = pool.id;
  poolMetadataUpdatedEvent.blockNumber = event.block.number;
  poolMetadataUpdatedEvent.timestamp = event.block.timestamp;
  poolMetadataUpdatedEvent.transactionHash = event.transaction.hash;

  poolMetadataUpdatedEvent.save();
}

export function handleRoleGranted(event: RoleGranted): void {
  const poolAdmin = new PoolAdmin(
    `${event.params.role.toHex()}-${event.params.account.toHex()}`
  );
  const contract = FlowSplitter.bind(event.address);
  const poolId = contract.getPoolByAdminRole(event.params.role).id;
  const pool = Pool.load(poolId.toHex());

  if (!pool) {
    log.warning("Pool not found for role admin {} and account {}", [
      event.params.role.toHex(),
      event.params.account.toHex(),
    ]);

    return;
  }

  poolAdmin.address = event.params.account;
  poolAdmin.adminRole = event.params.role;
  poolAdmin.pool = pool.id;
  poolAdmin.createdAtBlock = event.block.number;
  poolAdmin.createdAtTimestamp = event.block.timestamp;

  poolAdmin.save();

  const poolAdminAddedEvent = new PoolAdminAddedEvent(
    `PoolAdminAddedEvent-${event.transaction.hash.toHexString()}-${event.logIndex.toString()}`
  );

  poolAdminAddedEvent.address = event.params.account;
  poolAdminAddedEvent.adminRole = event.params.role;
  poolAdminAddedEvent.pool = pool.id;
  poolAdminAddedEvent.blockNumber = event.block.number;
  poolAdminAddedEvent.timestamp = event.block.timestamp;
  poolAdminAddedEvent.transactionHash = event.transaction.hash;

  poolAdminAddedEvent.save();
}

export function handleRoleRevoked(event: RoleRevoked): void {
  const id = `${event.params.role.toHex()}-${event.params.account.toHex()}`;

  store.remove("PoolAdmin", id);

  const contract = FlowSplitter.bind(event.address);
  const poolId = contract.getPoolByAdminRole(event.params.role).id;
  const pool = Pool.load(poolId.toHex());

  if (!pool) {
    log.warning("Pool not found for role admin {} and account {}", [
      event.params.role.toHex(),
      event.params.account.toHex(),
    ]);

    return;
  }

  const poolAdminRemovedEvent = new PoolAdminRemovedEvent(
    `PoolAdminRemovedEvent-${event.transaction.hash.toHexString()}-${event.logIndex.toString()}`
  );

  poolAdminRemovedEvent.address = event.params.account;
  poolAdminRemovedEvent.adminRole = event.params.role;
  poolAdminRemovedEvent.pool = pool.id;
  poolAdminRemovedEvent.blockNumber = event.block.number;
  poolAdminRemovedEvent.timestamp = event.block.timestamp;
  poolAdminRemovedEvent.transactionHash = event.transaction.hash;

  poolAdminRemovedEvent.save();
}
