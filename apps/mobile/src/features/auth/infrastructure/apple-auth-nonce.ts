import * as Crypto from "expo-crypto";

type CryptoModule = Pick<typeof Crypto, "getRandomBytes" | "digestStringAsync"> & {
  CryptoDigestAlgorithm: Pick<typeof Crypto.CryptoDigestAlgorithm, "SHA256">;
  CryptoEncoding: Pick<typeof Crypto.CryptoEncoding, "HEX">;
};

export async function createAppleAuthNonce(cryptoModule: CryptoModule = Crypto) {
  const rawNonce = bytesToHex(cryptoModule.getRandomBytes(32));
  const hashedNonce = await cryptoModule.digestStringAsync(
    cryptoModule.CryptoDigestAlgorithm.SHA256,
    rawNonce,
    { encoding: cryptoModule.CryptoEncoding.HEX }
  );

  return {
    rawNonce,
    hashedNonce
  };
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
}
