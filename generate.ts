import { $ } from "bun";
import fs from "fs";
import crypto from "crypto";
import clientConfig from "./config/client.json";
import serverConfig from "./config/server.json";

const uuid = crypto.randomUUID();
const randomShortId = crypto.randomBytes(8).toString("hex");
const realityKeyText = await $`sing-box generate reality-keypair`.text();

const realityPrivateKey = realityKeyText.split("\n")[0].split(": ")[1];
const realityPublicKey = realityKeyText.split("\n")[1].split(": ")[1];

console.log('UUID:', uuid);
console.log('Random Short ID:', randomShortId);
console.log('PrivateKey:', realityPrivateKey);
console.log('PublicKey:', realityPublicKey);

// Modify client config
const clientRealityOutbound = clientConfig.outbounds.find(outbound => outbound.flow === "xtls-rprx-vision");
if (!clientRealityOutbound) throw new Error("Client config not found");

clientRealityOutbound.tls!.reality!.public_key = realityPublicKey;
clientRealityOutbound.tls!.reality!.short_id = randomShortId;
clientRealityOutbound.uuid = uuid;
clientRealityOutbound.server = 'SERVER_IP_HERE';

// Modify server config
const serverRealityInbound = serverConfig.inbounds.find(inbound => inbound.type === "vless");
if (!serverRealityInbound) throw new Error("Server config not found");

serverRealityInbound.tls!.reality!.short_id = randomShortId;
serverRealityInbound.tls!.reality!.private_key = realityPrivateKey;
serverRealityInbound.users[0].uuid = uuid;

// Write client config
fs.writeFileSync("./output/client.json", JSON.stringify(clientConfig, null, 2));

// Write server config
fs.writeFileSync("./output/server.json", JSON.stringify(serverConfig, null, 2));