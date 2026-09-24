#!/usr/bin/env bash
set -euo pipefail

readonly DISTRIBUTION_REPOSITORY="adrianomedina-amssoft/amssoft-speedtest-control"
readonly RELEASES_URL="https://github.com/${DISTRIBUTION_REPOSITORY}/releases"
readonly RAW_MAIN_URL="https://raw.githubusercontent.com/${DISTRIBUTION_REPOSITORY}/main"
readonly RELEASE_PUBLIC_KEY_SHA256="dc6e3cb302b3c395758c84fa4ecd5563bce5368b48fb6ccaa23094d48e8e7eaf"

VERSION=""
BOOTSTRAP_ARGS=()
TEMP_DIR=""

usage() {
    cat <<'EOF'
Uso: install.sh [--version X.Y.Z] [--admin-cidr CIDR[,CIDR]] [--server-name NOME] [--no-start]

Sem --version, instala a release estavel mais recente. Somente Debian 12 amd64 e suportado.
EOF
}

fail() {
    printf 'Erro: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}

validate_version() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "versao invalida; use somente X.Y.Z estavel"
}

detect_latest_version() {
    local effective tag
    effective="$(curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
        --location --head --output /dev/null --write-out '%{url_effective}' \
        "${RELEASES_URL}/latest")"
    tag="${effective##*/}"
    [[ "$tag" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || fail "a release mais recente nao e uma versao estavel"
    printf '%s\n' "${BASH_REMATCH[1]}"
}

download() {
    local url="$1" destination="$2"
    curl --proto '=https' --tlsv1.2 --fail --silent --show-error \
        --location --retry 3 --retry-all-errors --connect-timeout 15 \
        --output "$destination" "$url"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                [[ $# -ge 2 ]] || fail "--version exige um valor"
                VERSION="${2#v}"
                validate_version "$VERSION"
                shift 2
                ;;
            --admin-cidr|--server-name)
                [[ $# -ge 2 ]] || fail "$1 exige um valor"
                BOOTSTRAP_ARGS+=("$1" "$2")
                shift 2
                ;;
            --no-start)
                BOOTSTRAP_ARGS+=("$1")
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                fail "argumento desconhecido: $1"
                ;;
        esac
    done
}

preflight() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]] || fail "execute com sudo ou como root"
    [[ -r /etc/os-release ]] || fail "nao foi possivel identificar o sistema operacional"

    local os_id os_version architecture
    os_id="$(sed -n 's/^ID=//p' /etc/os-release | tr -d '"' | head -n1)"
    os_version="$(sed -n 's/^VERSION_ID=//p' /etc/os-release | tr -d '"' | head -n1)"
    architecture="$(dpkg --print-architecture 2>/dev/null || true)"
    [[ "$os_id" == "debian" && "$os_version" == "12" && "$architecture" == "amd64" ]] ||
        fail "plataforma nao suportada: esperado Debian 12 amd64"

    for command_name in curl openssl sha256sum tar perl systemctl; do
        command -v "$command_name" >/dev/null 2>&1 || fail "comando obrigatorio ausente: $command_name"
    done
}

main() {
    parse_arguments "$@"
    preflight
    [[ -n "$VERSION" ]] || VERSION="$(detect_latest_version)"
    validate_version "$VERSION"

    local tag asset_base bundle
    tag="v${VERSION}"
    asset_base="${RELEASES_URL}/download/${tag}"
    bundle="ams-speedtest-control-${VERSION}-linux-amd64.tar.gz"
    TEMP_DIR="$(mktemp -d /tmp/ams-speedtest-control-install.XXXXXX)"
    trap cleanup EXIT INT TERM

    printf '[instalador] Baixando AMS SpeedTest Control %s\n' "$VERSION"
    download "${RAW_MAIN_URL}/release-public.pem" "${TEMP_DIR}/release-public.pem"
    download "${asset_base}/verify-bootstrap.sh" "${TEMP_DIR}/verify-bootstrap.sh"
    download "${asset_base}/bootstrap.sh" "${TEMP_DIR}/bootstrap.sh"
    download "${asset_base}/bootstrap.sh.sig" "${TEMP_DIR}/bootstrap.sh.sig"
    download "${asset_base}/manifest.sha256" "${TEMP_DIR}/manifest.sha256"
    download "${asset_base}/manifest.sha256.sig" "${TEMP_DIR}/manifest.sha256.sig"
    download "${asset_base}/${bundle}" "${TEMP_DIR}/${bundle}"

    local downloaded_key_hash
    downloaded_key_hash="$(sha256sum "${TEMP_DIR}/release-public.pem" | awk '{print $1}')"
    [[ "$RELEASE_PUBLIC_KEY_SHA256" =~ ^[0-9a-f]{64}$ ]] ||
        fail "instalador ainda nao possui uma ancora publica valida"
    [[ "$downloaded_key_hash" == "$RELEASE_PUBLIC_KEY_SHA256" ]] ||
        fail "a chave publica baixada nao corresponde a ancora do instalador"

    printf '[instalador] Validando bootstrap e release assinada\n'
    bash "${TEMP_DIR}/verify-bootstrap.sh" \
        "${TEMP_DIR}/release-public.pem" \
        "${TEMP_DIR}/bootstrap.sh" \
        "${TEMP_DIR}/bootstrap.sh.sig"

    bash "${TEMP_DIR}/bootstrap.sh" \
        --bundle "${TEMP_DIR}/${bundle}" \
        --manifest "${TEMP_DIR}/manifest.sha256" \
        --signature "${TEMP_DIR}/manifest.sha256.sig" \
        --public-key "${TEMP_DIR}/release-public.pem" \
        "${BOOTSTRAP_ARGS[@]}"

    printf '\nAMS SpeedTest Control %s instalado com sucesso.\n' "$VERSION"
    printf 'Acesse https://IP-DA-VM/admin/ para concluir a configuracao.\n'
}

if [[ "${AMS_INSTALLER_LIBRARY_MODE:-0}" != "1" ]]; then
    main "$@"
fi
