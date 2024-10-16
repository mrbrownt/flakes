{
  pkgs,
  lib,
  stdenv,
  fetchurl,
  undmg,
  makeWrapper,
  autoPatchelfHook,
  pango,
  gtk3,
  glibc,
  alsa-lib,
}:

let
  myZenVersion = "1.0.1-a.8";
  x86_64-darwin-hash = "13nns307xh1irkkzxxpnbc1kb217wcgvcy5qvm95l2qz0rsp05f8";
  aarch64-darwin-hash = "1vycqqf9kwv2xm3wmapxxz1kdzzglpaqmhis6jqlgk0vx0ja4qyf";
  x86_64-linux-hash = "1wcl52l7amjhj64rm7j78qc2i8l0yrj0lmkv31999qwqadvb6ris";
  sources = {
    x86_64-darwin = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.macos-x64.dmg";
      sha256 = x86_64-darwin-hash;
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.macos-aarch64.dmg";
      sha256 = aarch64-darwin-hash;
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.linux-specific.tar.bz2";
      sha256 = x86_64-linux-hash;
    };
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zen-browser";
  version = "${myZenVersion}";

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "unsupported system: ${stdenv.hostPlatform.system}");

  dontUnpack = stdenv.isDarwin;
  unpackPhase = ''
    mkdir -p $out
    tar xjvf ${finalAttrs.src} -C $out
  '';

  nativeBuildInputs = lib.optionals stdenv.isLinux [
    autoPatchelfHook
    stdenv.cc.cc.lib
    pango
    gtk3
    glibc
    alsa-lib
  ];
  buildInputs = [ makeWrapper ] ++ lib.optionals stdenv.isDarwin [ undmg ];

  buildPhase =
    if stdenv.isDarwin then
      ''
        undmg ${finalAttrs.src}
        mkdir -p $out/bin
        cp -r "Zen Browser.app" $out
        makeWrapper "$out/Zen Browser.app/Contents/MacOS/zen" "$out/bin/zen"
      ''
    else
      ''
        mkdir -p $out/bin
        makeWrapper "$out/zen/zen-bin" "$out/bin/zen"
      '';
})
