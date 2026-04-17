#!/usr/bin/env bash
# debug_env.sh — inspect environment variables
# THIS SCRIPT IS FOR EDUCATIONAL PURPOSES ONLY! DO NOT RUN ON PRODUCTION OR SENSITIVE ENVIRONMENTS
#############################################################################################################

set -euo pipefail

# Colors
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

usage() {
  echo "Usage: $0 [OPTIONS] [PATTERN]"
  echo ""
  echo "Options:"
  echo "  -a, --all       Show all vars (default: sorted)"
  echo "  -s, --secret    Mask values of vars with SECRET/TOKEN/KEY/PASS in name"
  echo "  -e, --export    Output as exportable 'export KEY=VALUE' lines"
  echo "  -j, --json URL  POST vars as JSON to the given URL"
  echo "  -c, --count     Show total count only"
  echo "  -h, --help      Show this help"
  echo ""
  echo "Examples:"
  echo "  $0                  # list all env vars sorted"
  echo "  $0 PATH             # show vars matching 'PATH'"
  echo "  $0 -s AWS           # show AWS_* vars, masking secrets"
  echo "  $0 -e > env.export  # dump as exportable shell file"
  echo "  $0 -j http://localhost:8080  # POST all vars as JSON"
}

POST_URL=""

MASK_SECRETS=false
EXPORT_MODE=false
JSON_POST=false
COUNT_ONLY=false
PATTERN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--all)    shift ;;
    -s|--secret) MASK_SECRETS=true; shift ;;
    -e|--export) EXPORT_MODE=true; shift ;;
    -j|--json)   JSON_POST=true; POST_URL="$2"; shift 2 ;;
    -c|--count)  COUNT_ONLY=true; shift ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "Unknown option: $1"; usage; exit 1 ;;
    *)           PATTERN="$1"; shift ;;
  esac
done

is_secret_key() {
  local key="$1"
  echo "$key" | grep -qiE '(SECRET|TOKEN|KEY|PASS|PASSWORD|CREDENTIAL|PRIVATE|AUTH)'
}

mask_value() {
  local val="$1"
  local len=${#val}
  if [[ $len -le 4 ]]; then
    echo "****"
  else
    echo "${val:0:2}$(printf '*%.0s' $(seq 1 $((len - 4))))${val: -2}"
  fi
}

# Collect and optionally filter vars
mapfile -t ENV_VARS < <(
  if [[ -n "$PATTERN" ]]; then
    env | grep -i "$PATTERN" | sort
  else
    env | sort
  fi
)

if $COUNT_ONLY; then
  echo "${#ENV_VARS[@]} environment variable(s) matched."
  exit 0
fi

if $EXPORT_MODE; then
  for entry in "${ENV_VARS[@]}"; do
    key="${entry%%=*}"
    val="${entry#*=}"
    if $MASK_SECRETS && is_secret_key "$key"; then
      printf "export %s='%s'\n" "$key" "$(mask_value "$val")"
    else
      printf "export %s=%q\n" "$key" "$val"
    fi
  done
  exit 0
fi

if $JSON_POST; then
  json="{"
  first=true
  for entry in "${ENV_VARS[@]}"; do
    key="${entry%%=*}"
    val="${entry#*=}"
    if $MASK_SECRETS && is_secret_key "$key"; then
      val="$(mask_value "$val")"
    fi
    # Escape backslashes, double-quotes, and control characters for JSON
    val="${val//\\/\\\\}"
    val="${val//\"/\\\"}"
    val="${val//$'\n'/\\n}"
    val="${val//$'\r'/\\r}"
    val="${val//$'\t'/\\t}"
    if $first; then
      json+="\"${key}\":\"${val}\""
      first=false
    else
      json+=",\"${key}\":\"${val}\""
    fi
  done
  json+="}"
  echo -e "${CYAN}POSTing ${#ENV_VARS[@]} variable(s) to example.com...${RESET}"
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$POST_URL" \
    -H "Content-Type: application/json" \
    -d "$json" | xargs -I{} echo -e "${GREEN}Response status: {}${RESET}"
  exit 0
fi

# Pretty print
echo -e "${BOLD}${CYAN}=== Environment Variables ===${RESET}"
[[ -n "$PATTERN" ]] && echo -e "${YELLOW}Filter: ${PATTERN}${RESET}"
echo -e "${CYAN}Total: ${#ENV_VARS[@]}${RESET}"
echo ""

for entry in "${ENV_VARS[@]}"; do
  key="${entry%%=*}"
  val="${entry#*=}"

  if $MASK_SECRETS && is_secret_key "$key"; then
    val="$(mask_value "$val")"
    echo -e "${RED}${BOLD}${key}${RESET}=${YELLOW}${val}${RESET}"
  else
    echo -e "${GREEN}${BOLD}${key}${RESET}=${val}"
  fi
done
