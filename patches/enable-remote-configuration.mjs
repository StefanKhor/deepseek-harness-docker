/**
 * Docker compatibility patches for DeepSeek Harness (fail-closed).
 *
 * 1) Server (lib/index.js): DSH_ALLOW_REMOTE_CONFIGURATION=1 lets privileged
 *    settings/credentials methods accept trustedHosts.
 *
 * 2) Browser (lib/client.js, served as /plugins/.../client.js): force
 *    connection.isLoopback = true so SettingsDescribeMirror uses host mode.
 *    Upstream sets memory mode when location.hostname is not loopback
 *    (LAN IP / public host) → "settings are unavailable in this browser".
 *
 * Safe in this image: dsh is only reachable via the compose nginx edge.
 */
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs'
import { resolve, join } from 'node:path'

const root = resolve(process.argv[2] ?? process.cwd())
const nm = resolve(root, 'node_modules')

function replaceExactlyOnce(source, before, after, description, file) {
  const occurrences = source.split(before).length - 1
  if (occurrences !== 1) {
    throw new Error(`${description}: expected 1 match, found ${occurrences} in ${file}`)
  }
  return source.replace(before, after)
}

function walkJs(dir, out = []) {
  if (!existsSync(dir)) return out
  for (const name of readdirSync(dir)) {
    if (name === '.bin' || name === '.cache') continue
    const p = join(dir, name)
    let st
    try { st = statSync(p) } catch { continue }
    if (st.isDirectory()) walkJs(p, out)
    else if (name.endsWith('.js')) out.push(p)
  }
  return out
}

// --- server privileged fence ---
const serverCandidates = [
  resolve(nm, '@deepseek-ai/dsh-client-connection/lib/index.js'),
  ...walkJs(nm).filter(p => p.replace(/\\/g, '/').endsWith('@deepseek-ai/dsh-client-connection/lib/index.js')),
]
const serverPath = serverCandidates.find(existsSync)
if (!serverPath) throw new Error('dsh-client-connection/lib/index.js not found under node_modules')

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

// --- browser isLoopback (every client.js copy) ---
const needle = 'isLoopback: pageLocation === void 0 || isLoopbackHostname(pageLocation.hostname),'
const replacement = 'isLoopback: true,'
let clientHits = 0
for (const file of walkJs(nm)) {
  const text = readFileSync(file, 'utf8')
  if (!text.includes(needle)) continue
  if (text.split(needle).length - 1 !== 1) {
    throw new Error(`browser isLoopback: expected 1 match in ${file}, found ${text.split(needle).length - 1}`)
  }
  writeFileSync(file, text.replace(needle, replacement))
  console.log(`Patched client ${file}`)
  clientHits += 1
}
if (clientHits === 0) {
  throw new Error('browser isLoopback pattern not found in any node_modules *.js (upstream changed?)')
}

// verify
const verify = walkJs(nm).some(f => readFileSync(f, 'utf8').includes('isLoopback: true,'))
if (!verify) throw new Error('post-patch verify failed: isLoopback: true not present')
console.log(`OK: patched ${clientHits} client bundle(s)`)
