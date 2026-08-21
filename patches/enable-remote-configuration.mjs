/**
 * Docker compatibility patches for DeepSeek Harness (fail-closed).
 *
 * 1) Server (lib/index.js): DSH_ALLOW_REMOTE_CONFIGURATION=1 lets privileged
 *    settings/credentials methods accept trustedHosts.
 *
 * 2) Browser (lib/client.js, served as /plugins/.../client.js): force
 *    connection.isLoopback = true so SettingsDescribeMirror uses host mode.
 *    Upstream sets memory mode when location.hostname is not loopback
 *    (LAN IP / public host) -> "settings are unavailable in this browser".
 *
 * Safe in this image: dsh is only reachable via the compose nginx edge.
 *
 * NOTE: This script is resilient to pattern changes in upstream packages.
 *       It will warn and skip patches if patterns don't match.
 */
import { readFileSync, writeFileSync, existsSync, readdirSync, statSync } from 'node:fs'
import { resolve, join } from 'node:path'

const root = resolve(process.argv[2] ?? process.cwd())
const nm = resolve(root, 'node_modules')

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
console.log('Searching for dsh-client-connection/lib/index.js...')
const serverCandidates = walkJs(nm).filter(p =>
  p.replace(/\\/g, '/').endsWith('deepseek-ai/dsh-client-connection/lib/index.js')
)
if (serverCandidates.length === 0) {
  console.log('WARN: dsh-client-connection/lib/index.js not found, skipping server patch')
} else {
  for (const serverPath of serverCandidates) {
    try {
      let server = readFileSync(serverPath, 'utf8')
      let patched = false

      // Try to find and patch PRIVILEGED_METHODS
      const privilegedMethodsMatch = server.match(/const PRIVILEGED_METHODS = new Set\(\[[\s\S]*?\]\);/)
      if (privilegedMethodsMatch) {
        const original = privilegedMethodsMatch[0]
        const patchedMethods = original.replace(
          ']);',
          `]);
const REMOTE_CONFIGURATION_METHODS = new Set([
\t"settings.describe",
\t"settings.update",
\t"settings.replace",
\t"settings.mutate",
\t"credentials.describe",
\t"credentials.set",
\t"credentials.unset",
\t"llm.discoverModels"
]);`
        )
        server = server.replace(original, patchedMethods)
        patched = true
      }

      // Try to find and patch trustedHosts
      const trustedHostsMatch = server.match(/\tconst trustedHosts = config\?\.trustedHosts \?\? \[\];\n\tconst maxRequestBodyBytes/)
      if (trustedHostsMatch) {
        const original = trustedHostsMatch[0]
        const patched = original.replace(
          `\tconst trustedHosts = config?.trustedHosts ?? [];
\tconst maxRequestBodyBytes`,
          `\tconst trustedHosts = config?.trustedHosts ?? [];
\tconst remoteConfigurationHosts = process.env.DSH_ALLOW_REMOTE_CONFIGURATION === "1" ? trustedHosts : [];
\tconst maxRequestBodyBytes`
        )
        server = server.replace(original, patched)
      }

      // Try to find and patch isTrustedApiRequest
      const trustedApiMatch = server.match(/if \(method !== void 0 && PRIVILEGED_METHODS\.has\(method\) && !isTrustedApiRequest\(request, \[\]\)\) return new Response\("forbidden", \{ status: 403 \}\);/)
      if (trustedApiMatch) {
        const original = trustedApiMatch[0]
        const patched = original.replace(
          `if (method !== void 0 && PRIVILEGED_METHODS.has(method) && !isTrustedApiRequest(request, [])) return new Response("forbidden", { status: 403 });`,
          `if (method !== void 0 && PRIVILEGED_METHODS.has(method)) {
\t\t\tconst acceptedHosts = REMOTE_CONFIGURATION_METHODS.has(method) ? remoteConfigurationHosts : [];
\t\t\tif (!isTrustedApiRequest(request, acceptedHosts)) return new Response("forbidden", { status: 403 });
\t\t}`
        )
        server = server.replace(original, patched)
      }

      if (patched) {
        writeFileSync(serverPath, server)
        console.log(`Patched server ${serverPath}`)
      } else {
        console.log(`WARN: No matching patterns in ${serverPath}, skipping`)
      }
    } catch (err) {
      console.log(`WARN: Failed to patch ${serverPath}: ${err.message}`)
    }
  }
}

// --- browser isLoopback (every client.js copy) ---
console.log('Searching for client isLoopback patterns...')
const needle = 'isLoopback: pageLocation === void 0 || isLoopbackHostname(pageLocation.hostname),'
const replacement = 'isLoopback: true,'
let clientHits = 0
for (const file of walkJs(nm)) {
  try {
    const text = readFileSync(file, 'utf8')
    if (!text.includes(needle)) continue
    if (text.split(needle).length - 1 !== 1) {
      console.log(`WARN: Expected 1 match in ${file}, found ${text.split(needle).length - 1}, skipping`)
      continue
    }
    writeFileSync(file, text.replace(needle, replacement))
    console.log(`Patched client ${file}`)
    clientHits += 1
  } catch (err) {
    console.log(`WARN: Failed to patch ${file}: ${err.message}`)
  }
}
if (clientHits === 0) {
  console.log('WARN: browser isLoopback pattern not found, skipping client patch')
}

console.log(`Done: patched ${clientHits} client bundle(s)`)
