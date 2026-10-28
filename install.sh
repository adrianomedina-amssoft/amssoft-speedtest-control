#!/usr/bin/env bash
set -euo pipefail

readonly DISTRIBUTION_REPOSITORY="adrianomedina-amssoft/amssoft-speedtest-control"
readonly RELEASES_URL="https://github.com/${DISTRIBUTION_REPOSITORY}/releases"
readonly RAW_MAIN_URL="https://raw.githubusercontent.com/${DISTRIBUTION_REPOSITORY}/main"
readonly RELEASE_PUBLIC_KEY_SHA256="9069fad97459e02e21c6e68cf9a0a3bae374b0dec815227594e5621f45b668ae"
readonly DEFAULT_ADMIN_CIDRS="10.0.0.0/8,100.64.0.0/10,172.16.0.0/12,192.168.0.0/16,2000::/3"
readonly DEPLOYMENT_CONFIG="/etc/ams-speedtest-control/deployment.env"

VERSION=""
BOOTSTRAP_ARGS=()
TEMP_DIR=""
MIGRATION_DIR=""
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
    if [[ -n "$MIGRATION_DIR" && "$MIGRATION_DIR" == /var/lib/ams-speedtest-control-privileged/legacy-migration.* && -d "$MIGRATION_DIR" ]]; then
        rm -rf -- "$MIGRATION_DIR"
    fi
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}

existing_installation() {
    [[ -e /usr/lib/ams-speedtest-control/VERSION ||
       -e /usr/lib/ams-speedtest-control/ams-speedtest-agent ||
       -e /usr/lib/ams-speedtest-control/ams-speedtest-control ||
       -e /etc/ams-speedtest-control/release-public.pem ]]
}

verify_release_bundle() {
    local key="$1" bundle="$2" manifest="$3" signature="$4" expected_line expected_hash
    openssl dgst -sha256 -verify "$key" -signature "$signature" "$manifest" >/dev/null ||
        fail "a assinatura do manifesto e invalida"
    expected_line="$(tr -d '\r' < "$manifest")"
    [[ "$expected_line" =~ ^[0-9a-f]{64}[[:space:]][[:space:]]ams-speedtest-control-[0-9]+\.[0-9]+\.[0-9]+-linux-amd64\.tar\.gz$ ]] ||
        fail "manifesto da release invalido"
    [[ "${expected_line#*  }" == "$(basename "$bundle")" ]] ||
        fail "manifesto nao corresponde ao pacote"
    expected_hash="${expected_line%% *}"
    [[ "$(sha256sum "$bundle" | awk '{print $1}')" == "$expected_hash" ]] ||
        fail "checksum do pacote invalido"
}

migrate_existing_installation() {
    local bundle="$1"
    local key=/etc/ams-speedtest-control/release-public.pem
    local installed_version installed_key_owner status
    [[ "${#BOOTSTRAP_ARGS[@]}" -eq 0 ]] ||
        fail "em migracao existente, configure dominio e redes pelo painel; opcoes de bootstrap nao se aplicam"
    [[ -f /usr/lib/ams-speedtest-control/VERSION && ! -L /usr/lib/ams-speedtest-control/VERSION &&
       -f /usr/lib/ams-speedtest-control/ams-speedtest-agent && ! -L /usr/lib/ams-speedtest-control/ams-speedtest-agent &&
       -f /usr/lib/ams-speedtest-control/ams-speedtest-control && ! -L /usr/lib/ams-speedtest-control/ams-speedtest-control &&
       -f "$key" && ! -L "$key" ]] || fail "instalacao existente incompleta; nenhuma alteracao foi feita"
    installed_key_owner="$(stat -c '%u:%g:%a' "$key")"
    [[ "$installed_key_owner" == 0:0:644 ]] || fail "chave de release instalada possui permissoes inseguras"
    cmp -s "$key" "${TEMP_DIR}/release-public.pem" ||
        fail "chave baixada difere da chave instalada; rotacao exige procedimento separado"
    installed_version="$(tr -d '\r\n' < /usr/lib/ams-speedtest-control/VERSION)"
    validate_version "$installed_version"
    [[ "$(printf '%s\n%s\n' "$installed_version" "$VERSION" | sort -V | tail -n1)" == "$VERSION" ]] ||
        fail "downgrade de versao nao permitido"
    [[ "$(printf '%s\n%s\n' 1.0.11 "$VERSION" | sort -V | tail -n1)" == "$VERSION" ]] ||
        fail "esta release ainda nao oferece a migracao protegida; aguarde v1.0.11 ou posterior"
    verify_release_bundle "$key" "${TEMP_DIR}/${bundle}" "${TEMP_DIR}/manifest.sha256" "${TEMP_DIR}/manifest.sha256.sig"
    command -v sqlite3 >/dev/null || fail "sqlite3 e obrigatorio para backup da migracao"
    command -v systemd-run >/dev/null || fail "systemd-run e obrigatorio para migracao protegida"
    local service
    for service in ams-speedtest-control.service ams-speedtest-agent.service ams-license-guard.service; do
        systemctl is-active --quiet "$service" || fail "$service deve estar ativo antes da migracao"
    done
    [[ ! -L /var/lib/ams-speedtest-control-privileged ]] || fail "diretorio privilegiado inseguro"
    install -d -o root -g root -m 0700 /var/lib/ams-speedtest-control-privileged
    [[ "$(stat -c '%u:%g:%a' /var/lib/ams-speedtest-control-privileged)" == 0:0:700 ]] ||
        fail "diretorio privilegiado inseguro"
    MIGRATION_DIR="$(mktemp -d /var/lib/ams-speedtest-control-privileged/legacy-migration.XXXXXX)"
    install -o root -g root -m 0600 "${TEMP_DIR}/${bundle}" "${MIGRATION_DIR}/${bundle}"
    install -o root -g root -m 0600 "${TEMP_DIR}/manifest.sha256" "${MIGRATION_DIR}/manifest.sha256"
    install -o root -g root -m 0600 "${TEMP_DIR}/manifest.sha256.sig" "${MIGRATION_DIR}/manifest.sha256.sig"
    install -o root -g root -m 0600 "${TEMP_DIR}/CHANGELOG-${VERSION}.md" "${MIGRATION_DIR}/CHANGELOG-${VERSION}.md"
    tar -xOf "${MIGRATION_DIR}/${bundle}" ./bin/ams-speedtest-agent > "${MIGRATION_DIR}/migration-agent"
    chmod 0700 "${MIGRATION_DIR}/migration-agent"
    [[ -s "${MIGRATION_DIR}/migration-agent" && ! -L "${MIGRATION_DIR}/migration-agent" ]] ||
        fail "agente candidato ausente no pacote assinado"
    sqlite3 /var/lib/ams-speedtest-control/control.db ".backup '${MIGRATION_DIR}/before-migration.db'"
    chmod 0600 "${MIGRATION_DIR}/before-migration.db"
    [[ "$(sqlite3 "${MIGRATION_DIR}/before-migration.db" 'PRAGMA integrity_check;')" == ok ]] ||
        fail "backup do banco nao passou na verificacao de integridade"
    printf '[instalador] Migrando %s para %s com recuperacao automatica protegida\n' "$installed_version" "$VERSION"
    systemd-run --unit=ams-control-product-update \
        --property=OnFailure=ams-control-update-recover-failure.service --collect --wait \
        "${MIGRATION_DIR}/migration-agent" --migrate-update \
        "${MIGRATION_DIR}/${bundle}" "${MIGRATION_DIR}/manifest.sha256" \
        "${MIGRATION_DIR}/manifest.sha256.sig" "${MIGRATION_DIR}/CHANGELOG-${VERSION}.md" \
        "${MIGRATION_DIR}/before-migration.db" || fail "migracao falhou; verifique o status e a recuperacao"
    status="$(jq -r '.status // empty' /var/lib/ams-speedtest-control/update-status.json 2>/dev/null || true)"
    [[ "$status" == succeeded && "$(tr -d '\r\n' < /usr/lib/ams-speedtest-control/VERSION)" == "$VERSION" ]] ||
        fail "migracao nao terminou com status saudavel"
    for service in ams-speedtest-control.service ams-speedtest-agent.service ams-license-guard.service; do
        systemctl is-active --quiet "$service" || fail "$service indisponivel apos migracao"
    done
    curl --fail --silent --show-error --insecure https://127.0.0.1/admin/api/v1/health >/dev/null ||
        fail "API indisponivel apos migracao"
}

validate_version() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "versao invalida; use somente X.Y.Z estavel"
}

# One budget per resource, including retries and backoff. Never retry integrity checks.
fetch_https() {
    local url="$1" destination="$2" label="$3" method="${4:-GET}"
    local attempt rc metadata code effective remaining timeout delay=2
    local started=$SECONDS
    local -a method_args=()
    [[ "$method" != HEAD ]] || method_args=(--head)
    for ((attempt = 1; attempt <= 8; attempt++)); do
        remaining=$((600 - SECONDS + started))
        ((remaining > 0)) || break
        timeout=90
        ((remaining >= timeout)) || timeout=$remaining
        printf '[instalador] %s: tentativa %s/8\n' "$label" "$attempt" >&2
        rc=0
        metadata="$(curl --disable --proto '=https' --proto-redir '=https' --tlsv1.2 \
            --fail --silent --show-error --location --max-redirs 10 \
            --connect-timeout 15 --max-time "$timeout" "${method_args[@]}" \
            --output "$destination" --write-out $'%{http_code}\n%{url_effective}' \
            "$url" 2>/dev/null)" || rc=$?
        code="${metadata%%$'\n'*}"
        effective="${metadata#*$'\n'}"
        if [[ "$rc" -eq 0 && "$code" == 200 ]]; then
            printf '%s\n' "$effective"
            return 0
        fi
        # curl 35 is an intermittent TLS handshake failure; certificate errors
        # (notably 51/60/77) are intentionally excluded.
        case "$rc:$code" in
            5:*|6:*|7:*|18:*|28:*|35:*|52:*|55:*|56:*|22:408|22:429|22:500|22:502|22:503|22:504) ;;
            *)
                printf '[instalador] %s: falha nao recuperavel (curl=%s, HTTP=%s).\n' "$label" "$rc" "$code" >&2
                return 1
                ;;
        esac
        remaining=$((600 - SECONDS + started))
        if ((attempt == 8 || remaining <= delay)); then
            break
        fi
        printf '[instalador] %s: conexao temporariamente indisponivel (curl=%s, HTTP=%s); nova tentativa em %ss.\n' \
            "$label" "$rc" "$code" "$delay" >&2
        sleep "$delay"
        delay=$((delay * 2))
        ((delay <= 30)) || delay=30
    done
    printf '[instalador] %s: limite de tentativas ou de 600s atingido; download interrompido.\n' "$label" >&2
    return 1
}

detect_latest_version() {
    local effective tag
    effective="$(fetch_https "${RELEASES_URL}/latest" /dev/null 'Consultar ultima versao' HEAD)" ||
        fail "nao foi possivel consultar a release mais recente"
    tag="${effective##*/}"
    [[ "$tag" =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]] || fail "a release mais recente nao e uma versao estavel"
    printf '%s\n' "${BASH_REMATCH[1]}"
}

download() {
    local url="$1" destination="$2" partial="${2}.part"
    if ! fetch_https "$url" "$partial" "$(basename "$destination")" >/dev/null; then
        rm -f -- "$partial"
        fail "nao foi possivel baixar $(basename "$destination"); nenhum arquivo incompleto sera instalado"
    fi
    mv -f -- "$partial" "$destination"
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
        printf '[instalador] Primeiro acesso IPv6 global coberto por 2000::/3. Depois do login, cadastre e teste seu prefixo antes de remover essa faixa ampla.\n'
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

    for command_name in curl openssl sha256sum tar perl systemctl sort; do
        command -v "$command_name" >/dev/null 2>&1 || fail "comando obrigatorio ausente: $command_name"
    done
}

main() {
    parse_arguments "$@"
    preflight
    if ! existing_installation; then
        prepare_initial_admin_cidr
    fi
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
    if existing_installation; then
        download "${asset_base}/CHANGELOG-${VERSION}.md" "${TEMP_DIR}/CHANGELOG-${VERSION}.md"
    fi

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

    if existing_installation; then
        migrate_existing_installation "$bundle"
    else
        bash "${TEMP_DIR}/bootstrap.sh" \
            --bundle "${TEMP_DIR}/${bundle}" \
            --manifest "${TEMP_DIR}/manifest.sha256" \
            --signature "${TEMP_DIR}/manifest.sha256.sig" \
            --public-key "${TEMP_DIR}/release-public.pem" \
            "${BOOTSTRAP_ARGS[@]}"
    fi

    server_name="$(read_installed_server_name /etc/default/ams-speedtest-control)" ||
        fail "a instalacao terminou sem um endereco administrativo valido"
    admin_url="$(admin_url_for_server_name "$server_name")"

    printf '\nAMS SpeedTest Control %s instalado com sucesso.\n' "$VERSION"
    printf 'Acesse %s para concluir a configuracao.\n' "$admin_url"
}

if [[ "${AMS_INSTALLER_LIBRARY_MODE:-0}" != "1" ]]; then
    main "$@"
fi
