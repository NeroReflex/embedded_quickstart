# Auto-Generated by cargo-bitbake 0.3.16
#
inherit cargo

# If this is git based prefer versioned ones if they exist
# DEFAULT_PREFERENCE = "-1"

# how to get login_ng could be as easy as but default to a git checkout:
# SRC_URI += "crate://crates.io/login_ng/0.7.6"
SRC_URI += "git://git@github.com/NeroReflex/login_ng.git;protocol=ssh;nobranch=1;branch=main"
SRCREV = "832309dff2b99035192ebe3d5e0bd258cd987462"
S = "${WORKDIR}/git"
CARGO_SRC_DIR = ""
PV:append = ".AUTOINC+832309dff2"

# please note if you have entries that do not begin with crate://
# you must change them to how that package can be fetched
SRC_URI += " \
    crate://crates.io/addr2line/0.24.2 \
    crate://crates.io/adler2/2.0.1 \
    crate://crates.io/aead/0.5.2 \
    crate://crates.io/aes-gcm/0.10.3 \
    crate://crates.io/aes/0.8.4 \
    crate://crates.io/aho-corasick/1.1.3 \
    crate://crates.io/android-tzdata/0.1.1 \
    crate://crates.io/android_system_properties/0.1.5 \
    crate://crates.io/argh/0.1.13 \
    crate://crates.io/argh_derive/0.1.13 \
    crate://crates.io/argh_shared/0.1.13 \
    crate://crates.io/async-broadcast/0.7.2 \
    crate://crates.io/async-channel/2.5.0 \
    crate://crates.io/async-executor/1.13.2 \
    crate://crates.io/async-io/2.4.1 \
    crate://crates.io/async-lock/3.4.0 \
    crate://crates.io/async-process/2.3.1 \
    crate://crates.io/async-recursion/1.1.1 \
    crate://crates.io/async-signal/0.2.11 \
    crate://crates.io/async-task/4.7.1 \
    crate://crates.io/async-trait/0.1.88 \
    crate://crates.io/atomic-waker/1.1.2 \
    crate://crates.io/autocfg/1.5.0 \
    crate://crates.io/backtrace/0.3.75 \
    crate://crates.io/base64/0.22.1 \
    crate://crates.io/base64ct/1.8.0 \
    crate://crates.io/bcrypt/0.17.0 \
    crate://crates.io/bindgen/0.71.1 \
    crate://crates.io/bitflags/2.9.1 \
    crate://crates.io/block-buffer/0.10.4 \
    crate://crates.io/blocking/1.6.2 \
    crate://crates.io/blowfish/0.9.1 \
    crate://crates.io/bumpalo/3.19.0 \
    crate://crates.io/byteorder/1.5.0 \
    crate://crates.io/bytevec2/0.3.1 \
    crate://crates.io/cc/1.2.29 \
    crate://crates.io/cexpr/0.6.0 \
    crate://crates.io/cfg-if/1.0.1 \
    crate://crates.io/cfg_aliases/0.2.1 \
    crate://crates.io/chrono/0.4.41 \
    crate://crates.io/cipher/0.4.4 \
    crate://crates.io/clang-sys/1.8.1 \
    crate://crates.io/concurrent-queue/2.5.0 \
    crate://crates.io/configparser/3.1.0 \
    crate://crates.io/const-oid/0.9.6 \
    crate://crates.io/core-foundation-sys/0.8.7 \
    crate://crates.io/cpufeatures/0.2.17 \
    crate://crates.io/crossbeam-utils/0.8.21 \
    crate://crates.io/crypto-common/0.1.6 \
    crate://crates.io/ctr/0.9.2 \
    crate://crates.io/der/0.7.10 \
    crate://crates.io/digest/0.10.7 \
    crate://crates.io/either/1.15.0 \
    crate://crates.io/endi/1.1.0 \
    crate://crates.io/enumflags2/0.7.12 \
    crate://crates.io/enumflags2_derive/0.7.12 \
    crate://crates.io/equivalent/1.0.2 \
    crate://crates.io/errno/0.3.13 \
    crate://crates.io/event-listener-strategy/0.5.4 \
    crate://crates.io/event-listener/5.4.0 \
    crate://crates.io/fastrand/2.3.0 \
    crate://crates.io/futures-core/0.3.31 \
    crate://crates.io/futures-io/0.3.31 \
    crate://crates.io/futures-lite/2.6.0 \
    crate://crates.io/generic-array/0.14.7 \
    crate://crates.io/getrandom/0.2.16 \
    crate://crates.io/getrandom/0.3.3 \
    crate://crates.io/ghash/0.5.1 \
    crate://crates.io/gimli/0.31.1 \
    crate://crates.io/glob/0.3.2 \
    crate://crates.io/greetd_ipc/0.10.3 \
    crate://crates.io/hashbrown/0.15.4 \
    crate://crates.io/heck/0.4.1 \
    crate://crates.io/hermit-abi/0.5.2 \
    crate://crates.io/hex/0.4.3 \
    crate://crates.io/hkdf/0.12.4 \
    crate://crates.io/hmac/0.12.1 \
    crate://crates.io/iana-time-zone-haiku/0.1.2 \
    crate://crates.io/iana-time-zone/0.1.63 \
    crate://crates.io/indexmap/2.10.0 \
    crate://crates.io/inout/0.1.4 \
    crate://crates.io/io-uring/0.7.8 \
    crate://crates.io/itertools/0.13.0 \
    crate://crates.io/itoa/1.0.15 \
    crate://crates.io/js-sys/0.3.77 \
    crate://crates.io/lazy_static/1.5.0 \
    crate://crates.io/libc/0.2.174 \
    crate://crates.io/libloading/0.8.8 \
    crate://crates.io/libm/0.2.15 \
    crate://crates.io/linux-raw-sys/0.9.4 \
    crate://crates.io/log/0.4.27 \
    crate://crates.io/loopdev-3/0.5.2 \
    crate://crates.io/memchr/2.7.5 \
    crate://crates.io/memoffset/0.9.1 \
    crate://crates.io/minimal-lexical/0.2.1 \
    crate://crates.io/miniz_oxide/0.8.9 \
    crate://crates.io/mio/1.0.4 \
    crate://crates.io/nix/0.30.1 \
    crate://crates.io/nom/7.1.3 \
    crate://crates.io/num-bigint-dig/0.8.4 \
    crate://crates.io/num-integer/0.1.46 \
    crate://crates.io/num-iter/0.1.45 \
    crate://crates.io/num-traits/0.2.19 \
    crate://crates.io/object/0.36.7 \
    crate://crates.io/once_cell/1.21.3 \
    crate://crates.io/opaque-debug/0.3.1 \
    crate://crates.io/ordered-stream/0.2.0 \
    crate://crates.io/parking/2.2.1 \
    crate://crates.io/pem-rfc7468/0.7.0 \
    crate://crates.io/pin-project-lite/0.2.16 \
    crate://crates.io/piper/0.2.4 \
    crate://crates.io/pkcs1/0.7.5 \
    crate://crates.io/pkcs8/0.10.2 \
    crate://crates.io/polling/3.8.0 \
    crate://crates.io/polyval/0.6.2 \
    crate://crates.io/ppv-lite86/0.2.21 \
    crate://crates.io/prettyplease/0.2.35 \
    crate://crates.io/proc-macro-crate/3.3.0 \
    crate://crates.io/proc-macro2/1.0.95 \
    crate://crates.io/quote/1.0.40 \
    crate://crates.io/r-efi/5.3.0 \
    crate://crates.io/rand/0.8.5 \
    crate://crates.io/rand_chacha/0.3.1 \
    crate://crates.io/rand_core/0.6.4 \
    crate://crates.io/regex-automata/0.4.9 \
    crate://crates.io/regex-syntax/0.8.5 \
    crate://crates.io/regex/1.11.1 \
    crate://crates.io/rpassword/7.4.0 \
    crate://crates.io/rs_hasher_ctx/0.1.3 \
    crate://crates.io/rs_internal_hasher/0.1.3 \
    crate://crates.io/rs_internal_state/0.1.3 \
    crate://crates.io/rs_n_bit_words/0.1.3 \
    crate://crates.io/rs_sha512/0.1.3 \
    crate://crates.io/rsa/0.9.8 \
    crate://crates.io/rtoolbox/0.0.3 \
    crate://crates.io/rust-fuzzy-search/0.1.1 \
    crate://crates.io/rustc-demangle/0.1.25 \
    crate://crates.io/rustc-hash/2.1.1 \
    crate://crates.io/rustix/1.0.7 \
    crate://crates.io/rustversion/1.0.21 \
    crate://crates.io/ryu/1.0.20 \
    crate://crates.io/serde/1.0.219 \
    crate://crates.io/serde_derive/1.0.219 \
    crate://crates.io/serde_json/1.0.140 \
    crate://crates.io/serde_repr/0.1.20 \
    crate://crates.io/sha2/0.10.9 \
    crate://crates.io/shlex/1.3.0 \
    crate://crates.io/signal-hook-registry/1.4.5 \
    crate://crates.io/signature/2.2.0 \
    crate://crates.io/slab/0.4.10 \
    crate://crates.io/smallvec/1.15.1 \
    crate://crates.io/smart-default/0.7.1 \
    crate://crates.io/spin/0.9.8 \
    crate://crates.io/spki/0.7.3 \
    crate://crates.io/static_assertions/1.1.0 \
    crate://crates.io/strum/0.24.1 \
    crate://crates.io/strum_macros/0.24.3 \
    crate://crates.io/subtle/2.6.1 \
    crate://crates.io/syn/1.0.109 \
    crate://crates.io/syn/2.0.104 \
    crate://crates.io/sys-mount/3.0.1 \
    crate://crates.io/tempfile/3.20.0 \
    crate://crates.io/thiserror-impl/1.0.69 \
    crate://crates.io/thiserror-impl/2.0.12 \
    crate://crates.io/thiserror/1.0.69 \
    crate://crates.io/thiserror/2.0.12 \
    crate://crates.io/tokio-macros/2.5.0 \
    crate://crates.io/tokio/1.46.1 \
    crate://crates.io/toml_datetime/0.6.11 \
    crate://crates.io/toml_edit/0.22.27 \
    crate://crates.io/tracing-attributes/0.1.30 \
    crate://crates.io/tracing-core/0.1.34 \
    crate://crates.io/tracing/0.1.41 \
    crate://crates.io/typenum/1.18.0 \
    crate://crates.io/uds_windows/1.1.0 \
    crate://crates.io/unicode-ident/1.0.18 \
    crate://crates.io/universal-hash/0.5.1 \
    crate://crates.io/users/0.11.0 \
    crate://crates.io/version_check/0.9.5 \
    crate://crates.io/wasi/0.11.1+wasi-snapshot-preview1 \
    crate://crates.io/wasi/0.14.2+wasi-0.2.4 \
    crate://crates.io/wasm-bindgen-backend/0.2.100 \
    crate://crates.io/wasm-bindgen-macro-support/0.2.100 \
    crate://crates.io/wasm-bindgen-macro/0.2.100 \
    crate://crates.io/wasm-bindgen-shared/0.2.100 \
    crate://crates.io/wasm-bindgen/0.2.100 \
    crate://crates.io/winapi-i686-pc-windows-gnu/0.4.0 \
    crate://crates.io/winapi-x86_64-pc-windows-gnu/0.4.0 \
    crate://crates.io/winapi/0.3.9 \
    crate://crates.io/windows-core/0.61.2 \
    crate://crates.io/windows-implement/0.60.0 \
    crate://crates.io/windows-interface/0.59.1 \
    crate://crates.io/windows-link/0.1.3 \
    crate://crates.io/windows-result/0.3.4 \
    crate://crates.io/windows-strings/0.4.2 \
    crate://crates.io/windows-sys/0.52.0 \
    crate://crates.io/windows-sys/0.59.0 \
    crate://crates.io/windows-sys/0.60.2 \
    crate://crates.io/windows-targets/0.52.6 \
    crate://crates.io/windows-targets/0.53.2 \
    crate://crates.io/windows_aarch64_gnullvm/0.52.6 \
    crate://crates.io/windows_aarch64_gnullvm/0.53.0 \
    crate://crates.io/windows_aarch64_msvc/0.52.6 \
    crate://crates.io/windows_aarch64_msvc/0.53.0 \
    crate://crates.io/windows_i686_gnu/0.52.6 \
    crate://crates.io/windows_i686_gnu/0.53.0 \
    crate://crates.io/windows_i686_gnullvm/0.52.6 \
    crate://crates.io/windows_i686_gnullvm/0.53.0 \
    crate://crates.io/windows_i686_msvc/0.52.6 \
    crate://crates.io/windows_i686_msvc/0.53.0 \
    crate://crates.io/windows_x86_64_gnu/0.52.6 \
    crate://crates.io/windows_x86_64_gnu/0.53.0 \
    crate://crates.io/windows_x86_64_gnullvm/0.52.6 \
    crate://crates.io/windows_x86_64_gnullvm/0.53.0 \
    crate://crates.io/windows_x86_64_msvc/0.52.6 \
    crate://crates.io/windows_x86_64_msvc/0.53.0 \
    crate://crates.io/winnow/0.7.11 \
    crate://crates.io/wit-bindgen-rt/0.39.0 \
    crate://crates.io/xattr/1.5.1 \
    crate://crates.io/zbus/5.8.0 \
    crate://crates.io/zbus_macros/5.8.0 \
    crate://crates.io/zbus_names/4.2.0 \
    crate://crates.io/zerocopy-derive/0.8.26 \
    crate://crates.io/zerocopy/0.8.26 \
    crate://crates.io/zeroize/1.8.1 \
    crate://crates.io/zvariant/5.6.0 \
    crate://crates.io/zvariant_derive/5.6.0 \
    crate://crates.io/zvariant_utils/3.2.0 \
    git://github.com/NeroReflex/pam-rs.git;protocol=https;nobranch=1;name=pam;destsuffix=pam \
"

SRCREV_FORMAT .= "_pam"
SRCREV_pam = "668eef5be397993489cdeddce64ded072fb330ff"
EXTRA_OECARGO_PATHS += "${WORKDIR}/pam"

# FIXME: update generateme with the real MD5 of the license file
LIC_FILES_CHKSUM = " \
    file://LICENSE.md;md5=83ea31b4ebf7c17dcd4f18612a0b1df4 \
"

SUMMARY = "A set of software and utilities for managing every aspect of user login."
HOMEPAGE = "https://github.com/NeroReflex/login_ng"
LICENSE = "LICENSE.md"

# includes this file if it exists but does not fail
# this is useful for anything you may want to override from
# what cargo-bitbake generates.
include login_ng-${PV}.inc
include login_ng.inc
