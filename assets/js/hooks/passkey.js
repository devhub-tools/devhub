export const PasskeyHook = {
  mounted() {
    window.addEventListener("register_passkey", event => this.pushEvent("register_passkey", event.data))
    this.handleEvent("start_passkey_registration", startPasskeyRegistration)
    window.addEventListener("authenticate_passkey", event => this.pushEvent(event.phxEvent, event.data))
    this.handleEvent("start_passkey_authentication", startPasskeyAuthentication)
  },
}

const startPasskeyRegistration = ({ challenge, attestation, userId, displayName, rpId }) => {
  navigator.credentials.create({
    publicKey: {
      challenge: _base64ToArrayBuffer(challenge),
      rp: {
        id: rpId,
        name: "Devhub"
      },
      user: {
        id: new TextEncoder().encode(userId).buffer,
        name: displayName,
        displayName: displayName
      },
      pubKeyCredParams: [
        {
          type: "public-key", alg: -7 // "ES256" IANA COSE Algorithms registry
        }
      ],
      attestation: attestation,
      authenticatorSelection: {
        residentKey: "preferred"
      }
    }
  }).then((newCredential) => {
    const rawId = _arrayBufferToBase64(newCredential.rawId)
    const type = newCredential.type
    const clientDataJSON = _arrayBufferToString(newCredential.response.clientDataJSON)
    const attestationObject = _arrayBufferToBase64(newCredential.response.attestationObject)
    const event = new Event("register_passkey")
    event.data = { rawId, type, clientDataJSON, attestationObject }
    window.dispatchEvent(event)
  }).catch((err) => {
    console.log(err)
  })
}

const startPasskeyAuthentication = ({ challenge, credIds, phxEvent }) => {
  navigator.credentials.get({
    publicKey: {
      challenge: _base64ToArrayBuffer(challenge),
      allowCredentials: credIds.map(credId => ({
        type: "public-key",
        id: _base64ToArrayBuffer(credId)
      }))
    }
  }).then((newCredential) => {
    const rawId = _arrayBufferToBase64(newCredential.rawId)
    const type = newCredential.type
    const clientDataJSON = _arrayBufferToString(newCredential.response.clientDataJSON)
    const authenticatorData = _arrayBufferToBase64(newCredential.response.authenticatorData)
    const sig = _arrayBufferToBase64(newCredential.response.signature)
    const event = new Event("authenticate_passkey")
    event.data = { rawId, type, clientDataJSON, authenticatorData, sig }
    event.phxEvent = phxEvent
    window.dispatchEvent(event)
  }).catch((err) => {
    console.log(err)
  })
}

function _arrayBufferToString(buffer) {
  var binary = ""
  var bytes = new Uint8Array(buffer)
  var len = bytes.byteLength
  for (var i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return binary
}

function _arrayBufferToBase64(buffer) {
  var binary = ""
  var bytes = new Uint8Array(buffer)
  var len = bytes.byteLength
  for (var i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return window.btoa(binary)
}

function _base64ToArrayBuffer(base64) {
  var binary_string = window.atob(base64)
  var len = binary_string.length
  var bytes = new Uint8Array(len)
  for (var i = 0; i < len; i++) {
    bytes[i] = binary_string.charCodeAt(i)
  }
  return bytes.buffer
}