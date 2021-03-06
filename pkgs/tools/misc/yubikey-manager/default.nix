{ python3Packages, fetchurl, lib, fetchpatch,
  yubikey-personalization, libu2f-host, libusb1 }:

python3Packages.buildPythonPackage rec {
  pname = "yubikey-manager";
  version = "3.1.2";

  srcs = fetchurl {
    url = "https://developers.yubico.com/${pname}/Releases/${pname}-${version}.tar.gz";
    hash = "sha256-dwnIOuu0QyWRl6RSdyQw7dGsAZ4xpXpx6jOpCkp4efE=";
  };

  patches = [
    # https://github.com/Yubico/yubikey-manager/issues/279
    (fetchpatch {
      name = "openpgp-kdf-support.patch";
      url = "https://github.com/Yubico/yubikey-manager/commit/4bea80dc4e258d1044effa53a2fc224a3ed90672.patch";
      sha256 = "1ivzpafz3zpbfhdpc2s13q0jhdsj9ly08brmpkbkv648amg4sk83";
    })
  ];

  propagatedBuildInputs =
    with python3Packages; [
      click
      cryptography
      pyscard
      pyusb
      pyopenssl
      six
      fido2
    ] ++ [
      libu2f-host
      libusb1
      yubikey-personalization
    ];

  makeWrapperArgs = [
    "--prefix" "LD_LIBRARY_PATH" ":"
    (lib.makeLibraryPath [ libu2f-host libusb1 yubikey-personalization ])
  ];

  postInstall = ''
    mkdir -p "$out/man/man1"
    cp man/ykman.1 "$out/man/man1"

    mkdir -p $out/share/bash-completion/completions
    _YKMAN_COMPLETE=source $out/bin/ykman > $out/share/bash-completion/completions/ykman || :
    mkdir -p $out/share/zsh/site-functions/
    _YKMAN_COMPLETE=source_zsh "$out/bin/ykman" > "$out/share/zsh/site-functions/_ykman" || :
    substituteInPlace "$out/share/zsh/site-functions/_ykman" \
      --replace 'compdef _ykman_completion ykman;' '_ykman_completion "$@"'
  '';

  # See https://github.com/NixOS/nixpkgs/issues/29169
  doCheck = false;

  meta = with lib; {
    homepage = "https://developers.yubico.com/yubikey-manager";
    description = "Command line tool for configuring any YubiKey over all USB transports";

    license = licenses.bsd2;
    platforms = platforms.unix;
    maintainers = with maintainers; [ benley mic92 ];
  };
}
