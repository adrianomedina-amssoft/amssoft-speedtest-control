#!/usr/bin/env bash
set -euo pipefail

readonly DISTRIBUTION_REPOSITORY="adrianomedina-amssoft/amssoft-speedtest-control"
readonly RELEASES_URL="https://github.com/${DISTRIBUTION_REPOSITORY}/releases"
readonly RAW_MAIN_URL="https://raw.githubusercontent.com/${DISTRIBUTION_REPOSITORY}/main"
readonly RELEASE_PUBLIC_KEY_SHA256="9069fad97459e02e21c6e68cf9a0a3bae374b0dec815227594e5621f45b668ae"
readonly DEFAULT_ADMIN_CIDRS="10.0.0.0/8,100.64.0.0/10,172.16.0.0/12,192.168.0.0/16"
readonly DEPLOYMENT_CONFIG="/etc/ams-speedtest-control/deployment.env"

VERSION=""
BOOTSTRAP_ARGS=()
TEMP_DIR=""
ADMIN_CIDR_EXPLICIT=0

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

verify_bootstrap() {
    local public_key="$1" bootstrap="$2" signature="$3"
    openssl dgst -sha256 \
        -verify "$public_key" \
        -signature "$signature" \
        "$bootstrap" >/dev/null ||
        fail "a assinatura do bootstrap e invalida"
}

valid_ip_address() {
    perl -MSocket=AF_INET,AF_INET6,inet_pton -e '
        exit !(defined inet_pton(index($ARGV[0], ":") >= 0 ? AF_INET6 : AF_INET, $ARGV[0]));
    ' "$1"
}

detect_ssh_client_address() {
    local connection="${SSH_CONNECTION:-}" process_id="${PPID:-}" parent_id depth=0
    while [[ -z "$connection" && "$process_id" =~ ^[0-9]+$ && "$process_id" -gt 1 && "$depth" -lt 12 ]]; do
        if [[ -r "/proc/${process_id}/environ" ]]; then
            connection="$(tr '\0' '\n' < "/proc/${process_id}/environ" |
                sed -n 's/^SSH_CONNECTION=\([^ ]*\) .*/\1/p' | head -n1)"
        fi
        [[ -r "/proc/${process_id}/stat" ]] || break
        parent_id="$(awk '{print $4}' "/proc/${process_id}/stat")"
        [[ "$parent_id" != "$process_id" ]] || break
        process_id="$parent_id"
        depth=$((depth + 1))
    done

    connection="${connection%% *}"
    [[ -n "$connection" ]] && valid_ip_address "$connection" && printf '%s\n' "$connection"
}

administrative_network_for_address() {
    perl -MSocket=AF_INET,AF_INET6,inet_pton,inet_ntop -e '
        my $address = $ARGV[0];
        if (index($address, ":") >= 0) {
            my $packed = inet_pton(AF_INET6, $address) or exit 1;
            substr($packed, 8, 8, "\0" x 8);
            print inet_ntop(AF_INET6, $packed), "/64";
        } else {
            my $packed = inet_pton(AF_INET, $address) or exit 1;
            my $network = unpack("N", $packed) & 0xffffff00;
            print inet_ntop(AF_INET, pack("N", $network)), "/24";
        }
    ' "$1"
}

read_installed_server_name() {
    local config_path="$1" server_name
    [[ -r "$config_path" ]] || return 1
    server_name="$(sed -n 's/^AMS_CONTROL_SERVER_NAME=//p' "$config_path" | tail -n1)"
    [[ -n "$server_name" ]] || return 1
    if valid_ip_address "$server_name" || [[ "$server_name" =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ ]]; then
        printf '%s\n' "$server_name"
        return 0
    fi
    return 1
}

admin_url_for_server_name() {
    local server_name="$1"
    if [[ "$server_name" == *:* ]]; then
        printf 'https://[%s]/admin/\n' "$server_name"
    else
        printf 'https://%s/admin/\n' "$server_name"
    fi
}

deployment_config_exists() {
    [[ -e "$DEPLOYMENT_CONFIG" ]]
}

prepare_initial_admin_cidr() {
    [[ "$ADMIN_CIDR_EXPLICIT" -eq 0 ]] || return 0
    ! deployment_config_exists || return 0

    local client_address client_network
    client_address="$(detect_ssh_client_address || true)"
    [[ -n "$client_address" ]] || return 0
    if [[ "$client_address" == *:* ]]; then
        printf '[instalador] SSH por IPv6 detectado. IPv6 administrativo permanece desativado; use --admin-cidr explicitamente se este for o unico caminho de acesso.\n'
        return 0
    fi
    client_network="$(administrative_network_for_address "$client_address")"
    BOOTSTRAP_ARGS+=(--admin-cidr "${DEFAULT_ADMIN_CIDRS},${client_network}")
    printf '[instalador] Acesso administrativo inicial autorizado para o operador SSH atual (%s).\n' \
        "$client_network"
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
                [[ "$1" != "--admin-cidr" ]] || ADMIN_CIDR_EXPLICIT=1
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
    prepare_initial_admin_cidr
    [[ -n "$VERSION" ]] || VERSION="$(detect_latest_version)"
    validate_version "$VERSION"

    local tag asset_base bundle server_name admin_url
    tag="v${VERSION}"
    asset_base="${RELEASES_URL}/download/${tag}"
    bundle="ams-speedtest-control-${VERSION}-linux-amd64.tar.gz"
    TEMP_DIR="$(mktemp -d /tmp/ams-speedtest-control-install.XXXXXX)"
    trap cleanup EXIT INT TERM

    printf '[instalador] Baixando AMS SpeedTest Control %s\n' "$VERSION"
    download "${RAW_MAIN_URL}/release-public.pem" "${TEMP_DIR}/release-public.pem"
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
    verify_bootstrap \
        "${TEMP_DIR}/release-public.pem" \
        "${TEMP_DIR}/bootstrap.sh" \
        "${TEMP_DIR}/bootstrap.sh.sig"

    bash "${TEMP_DIR}/bootstrap.sh" \
        --bundle "${TEMP_DIR}/${bundle}" \
        --manifest "${TEMP_DIR}/manifest.sha256" \
        --signature "${TEMP_DIR}/manifest.sha256.sig" \
        --public-key "${TEMP_DIR}/release-public.pem" \
        "${BOOTSTRAP_ARGS[@]}"

    server_name="$(read_installed_server_name /etc/default/ams-speedtest-control)" ||
        fail "a instalacao terminou sem um endereco administrativo valido"
    admin_url="$(admin_url_for_server_name "$server_name")"

    printf '\nAMS SpeedTest Control %s instalado com sucesso.\n' "$VERSION"
    printf 'Acesse %s para concluir a configuracao.\n' "$admin_url"
}

if [[ "${AMS_INSTALLER_LIBRARY_MODE:-0}" != "1" ]]; then
    main "$@"
fi
