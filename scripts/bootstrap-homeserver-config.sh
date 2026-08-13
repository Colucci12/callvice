#!/usr/bin/env bash
# Rode NO HOMESERVER (SSH), uma vez, para gerar configs em /home/shark/stoat/config.
# Uso: bash scripts/bootstrap-homeserver-config.sh
# Ou, sem clonar o fork: curl -fsSL <raw-url> | bash
#
# NÃO rode isto no clone do Portainer / neste diretório do Git se já houver
# compose.override.yml nosso — o generate_config.sh sobrescreve o override.

set -euo pipefail

DOMAIN="${STOAT_DOMAIN:-callvice.zvcore.com}"
CONFIG_DIR="${STOAT_CONFIG_DIR:-/home/shark/stoat/config}"
DATA_DIR="${STOAT_DATA_DIR:-/home/shark/stoat/data}"
TMP_DIR="${TMPDIR:-/tmp}/stoat-config-gen-$$"

echo "==> Criando ${CONFIG_DIR} e ${DATA_DIR}"
mkdir -p "${CONFIG_DIR}" "${DATA_DIR}"

if [[ -f "${CONFIG_DIR}/secrets.env" ]]; then
  echo "AVISO: já existe ${CONFIG_DIR}/secrets.env"
  echo "Abortando para não sobrescrever secrets. Remova-os manualmente se quiser regenerar,"
  echo "ou use generate_config.sh --overwrite em /tmp com o secrets.env atual copiado."
  exit 1
fi

echo "==> Clone temporário do oficial em ${TMP_DIR}"
git clone --depth 1 https://github.com/stoatchat/self-hosted.git "${TMP_DIR}"
cd "${TMP_DIR}"
chmod +x ./generate_config.sh

echo "==> generate_config.sh ${DOMAIN} (reverse proxy=y, video=Y)"
# Respostas: behind reverse proxy = y; camera/screen = Y (default)
printf 'y\nY\n' | ./generate_config.sh "${DOMAIN}"

echo "==> Copiando os 5 arquivos (NÃO o compose.override.yml do script)"
cp -v Revolt.toml secrets.env livekit.yml .env.web stoat.json "${CONFIG_DIR}/"

echo "==> Limpando ${TMP_DIR}"
cd /
rm -rf "${TMP_DIR}"

echo
echo "Pronto. Arquivos em ${CONFIG_DIR}:"
ls -la "${CONFIG_DIR}"
echo
echo "FAÇA BACKUP de ${CONFIG_DIR}/secrets.env (fora do Git)."
echo "Depois: port forward TCP 7881 + UDP 50000-50100 e deploy no Portainer (branch home-server)."
