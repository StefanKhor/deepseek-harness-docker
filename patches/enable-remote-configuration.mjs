/**
 * Docker / reverse-proxy compatibility patches for @deepseek-ai/dsh-client-connection.
 *
 * 1) Server: when DSH_ALLOW_REMOTE_CONFIGURATION=1, privileged settings/credentials
 *    APIs accept trustedHosts (AlliotTech approach). Fail-closed if source drifts.
 *
 * 2) Browser: force connection.isLoopback = true so SettingsDescribeMirror uses
 *    host persistence. Upstream sets memory mode for non-loopback page hostnames
 *    (e.g. https://10.0.0.6:8443), which shows "settings are unavailable in this browser"
 *    even when the proxy rewrites Host to 127.0.0.1. Safe in this image because
 *    dsh is not published publicly — only nginx reaches it.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs'
import { resolve } from 'node:path'

const root = resolve(process.argv[2] ?? process.cwd())

function replaceExactlyOnce(source, before, after, description, file) {
  const occurrences = source.split(before).length - 1
  if (occurrences !== 1) {
    throw new Error(`${description}: expected 1 match, found ${occurrences} in ${file}`)
  }
  return source.replace(before, after)
}

// --- server-side privileged fence ---
const serverPath = resolve(root, 'node_modules/@deepseek-ai/dsh-client-connection/lib/index.js')
if (!existsSync(serverPath)) {
  throw new Error(`missing ${serverPath}`)
}
let server = readFileSync(serverPath, 'utf8')

server = replaceExactlyOnce(
  server,
  `const PRIVILEGED_METHODS = new Set([
\t"agentPreset.read",
\t"agentPreset.copy",
\t"agentPreset.openDocument",
\t"agentPreset.remove",
\t"host.pickDirectory",
\t"host.openPath",
\t"settings.describe",
\t"settings.openDocument",
\t"settings.update",
\t"settings.replace",
\t"settings.mutate",
\t"credentials.describe",
\t"credentials.set",
\t"credentials.unset",
\t"llm.discoverModels"
]);`,
  `const PRIVILEGED_METHODS = new Set([
\t"agentPreset.read",
\t"agentPreset.copy",
\t"agentPreset.openDocument",
\t"agentPreset.remove",
\t"host.pickDirectory",
\t"host.openPath",
\t"settings.describe",
\t"settings.openDocument",
\t"settings.update",
\t"settings.replace",
\t"settings.mutate",
\t"credentials.describe",
\t"credentials.set",
\t"credentials.unset",
\t"llm.discoverModels"
]);
const REMOTE_CONFIGURATION_METHODS = new Set([
\t"settings.describe",
\t"settings.update",
\t"settings.replace",
\t"settings.mutate",
\t"credentials.describe",
\t"credentials.set",
\t"credentials.unset",
\t"llm.discoverModels"
]);`,
  'privileged method registry',
  serverPath,
)

server = replaceExactlyOnce(
  server,
  `\tconst trustedHosts = config?.trustedHosts ?? [];
\tconst maxRequestBodyBytes = config?.maxRequestBodyBytes ?? 167772160;`,
  `\tconst trustedHosts = config?.trustedHosts ?? [];
\tconst remoteConfigurationHosts = process.env.DSH_ALLOW_REMOTE_CONFIGURATION === "1" ? trustedHosts : [];
\tconst maxRequestBodyBytes = config?.maxRequestBodyBytes ?? 167772160;`,
  'remote configuration trust list',
  serverPath,
)

server = replaceExactlyOnce(
  server,
  `\t\tif (method !== void 0 && PRIVILEGED_METHODS.has(method) && !isTrustedApiRequest(request, [])) return new Response("forbidden", { status: 403 });`,
  `\t\tif (method !== void 0 && PRIVILEGED_METHODS.has(method)) {
\t\t\tconst acceptedHosts = REMOTE_CONFIGURATION_METHODS.has(method) ? remoteConfigurationHosts : [];
\t\t\tif (!isTrustedApiRequest(request, acceptedHosts)) return new Response("forbidden", { status: 403 });
\t\t}`,
  'privileged request fence',
  serverPath,
)

writeFileSync(serverPath, server)
console.log(`Patched server ${serverPath}`)

// --- browser-side isLoopback (settings mirror host vs memory) ---
const clientPath = resolve(root, 'node_modules/@deepseek-ai/dsh-client-connection/lib/client.js')
if (!existsSync(clientPath)) {
  throw new Error(`missing ${clientPath}`)
}
let client = readFileSync(clientPath, 'utf8')

// Force host-mode settings for all page origins in this container image.
client = replaceExactlyOnce(
  client,
  `isLoopback: pageLocation === void 0 || isLoopbackHostname(pageLocation.hostname),`,
  `isLoopback: true,`,
  'browser connection isLoopback',
  clientPath,
)

writeFileSync(clientPath, client)
console.log(`Patched client ${clientPath}`)
