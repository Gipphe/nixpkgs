# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, cereal, certificate, cprngAes, cryptohash, cryptoPubkey
, cryptoRandom, mtl, network, QuickCheck, testFramework
, testFrameworkQuickcheck2, time
}:

cabal.mkDerivation (self: {
  pname = "tls";
  version = "1.1.5";
  sha256 = "1ja03x3i7dgjpy22h4shnni1xslph8i8q4accqq8njpqpz54c84c";
  buildDepends = [
    cereal certificate cryptohash cryptoPubkey cryptoRandom mtl network
  ];
  testDepends = [
    cereal certificate cprngAes cryptoPubkey cryptoRandom mtl
    QuickCheck testFramework testFrameworkQuickcheck2 time
  ];
  doCheck = false;
  meta = {
    homepage = "http://github.com/vincenthz/hs-tls";
    description = "TLS/SSL protocol native implementation (Server and Client)";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    hydraPlatforms = self.stdenv.lib.platforms.none;
    maintainers = [ self.stdenv.lib.maintainers.andres ];
  };
})
