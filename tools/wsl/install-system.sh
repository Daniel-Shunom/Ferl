#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
test "$(id -u)" -eq 0
. /etc/os-release
test "$ID" = ubuntu && test "$VERSION_CODENAME" = noble
apt-get update -qq
apt-get install -y -qq ca-certificates curl gnupg build-essential unzip xz-utils ripgrep python3 nodejs npm wl-clipboard
key_file=/usr/share/keyrings/erlang-for-elp.gpg
curl --fail --silent --show-error --location \
  https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA \
  | gpg --dearmor --batch --yes --output "$key_file"
source_file=/etc/apt/sources.list.d/erlang-for-elp.list
if test -f "$source_file"; then
  mkdir -p /var/backups/nvim-elp
  cp -a "$source_file" "/var/backups/nvim-elp/erlang-for-elp.list.$(date +%Y%m%d-%H%M%S)"
fi
printf '%s\n' \
  'deb [arch=amd64 signed-by=/usr/share/keyrings/erlang-for-elp.gpg] https://deb1.rabbitmq.com/rabbitmq-erlang/ubuntu/noble noble main' \
  'deb [arch=amd64 signed-by=/usr/share/keyrings/erlang-for-elp.gpg] https://deb2.rabbitmq.com/rabbitmq-erlang/ubuntu/noble noble main' \
  > "$source_file"
apt-get update -qq
otp_version=$(apt-cache madison erlang-base | awk '!found && $3 ~ /^1:27[.]3[.]/ {print $3; found=1}')
test -n "$otp_version"
packages=()
for package in base dev parsetools crypto asn1 inets public-key ssl syntax-tools tools eunit edoc dialyzer xmerl src; do
  packages+=("erlang-$package=$otp_version")
done
apt-get install -y -qq --no-install-recommends "${packages[@]}"
erl -noshell -eval 'io:format("Installed Erlang/OTP ~s~n", [erlang:system_info(otp_release)]), halt().'
