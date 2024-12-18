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
import { Pool, PoolAdmin } from "../generated/schema";

export function handlePoolCreated(event: PoolCreated): void {
  const pool = new Pool(event.params.poolId.toHex());
  const adminRole = Bytes.fromByteArray(
    crypto.keccak256(
      ethereum
        .encode(ethereum.Value.fromUnsignedBigInt(event.params.poolId))!
        .concat(Bytes.fromUTF8("admin"))
    )
  );

  pool.poolAddress = event.params.poolAddress;
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
  poolAdmin.poolId = pool.id;
  poolAdmin.poolAddress = pool.poolAddress;
  poolAdmin.poolToken = pool.token;
  poolAdmin.poolMetadata = pool.metadata;
  poolAdmin.createdAtBlock = event.block.number;
  poolAdmin.createdAtTimestamp = event.block.timestamp;

  poolAdmin.save();
}

export function handleRoleRevoked(event: RoleRevoked): void {
  const id = `${event.params.role.toHex()}-${event.params.account.toHex()}`;

  store.remove("PoolAdmin", id);
}
