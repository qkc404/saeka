#!/bin/bash

BOLD='\033[1m'; RESET='\033[0m'
GREEN='\033[1;32m'; RED='\033[1;31m'; CYAN='\033[1;36m'
YELLOW='\033[1;33m'; BLUE='\033[1;34m'

loading() {
    local text="$1"
    local spin="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    for ((i=0; i<5; i++)); do
        for ((j=0; j<${#spin}; j++)); do
            echo -ne "\r${CYAN}${spin:$j:1} ${text}...${RESET}"
            sleep 0.04
        done
    done
    echo -ne "\r${GREEN}DONE: ${text}${RESET}\n"
}

clear
echo -e "${BLUE}────────────────────────────────────────────────────${RESET}"
echo -e "${CYAN}    (⁠ ⁠ꈍ⁠ᴗ⁠ꈍ⁠) TROJAN FAST DEPLOYER BY SAEKA${RESET}"
echo -e "${BLUE}────────────────────────────────────────────────────${RESET}"

PROJECT_ID=$(gcloud config get-value project 2>/dev/null | tr -d '[:space:]')
if [ -z "$PROJECT_ID" ]; then
    echo -e "${YELLOW}No active GCP Project set in Cloud Shell!${RESET}"
    read -r -p "Enter your GCP Project ID: " PROJECT_ID
    gcloud config set project "$PROJECT_ID"
fi

read -r -p "$(echo -e "${CYAN}  SERVICE NAME [saeka-tunnel]: ${RESET}")" INPUT_NAME
SERVICE_NAME=${INPUT_NAME:-saeka-tunnel}

read -r -p "$(echo -e "${CYAN}  DECOY URL [google.com]: ${RESET}")" USER_DECOY
FINAL_DECOY=${USER_DECOY:-google.com}
CLEAN_DECOY=$(echo "$FINAL_DECOY" | sed 's|https\?://||' | sed 's|/.*$||')

echo -e "\n${CYAN} SELECT COMPUTE TIER (Low Latency Recommendation: Tier 2 or 3):${RESET}"
echo -e "${YELLOW}  1) 1 vCPU / 2Gi RAM${RESET}"
echo -e "${YELLOW}  2) 2 vCPU / 4Gi RAM [Standard Plan]${RESET}"
echo -e "${YELLOW}  3) 4 vCPU / 8Gi RAM [High Throughput]${RESET}"
read -r -p "$(echo -e "${CYAN}  CHOICE [2]: ${RESET}")" PAIR_CHOICE

case "$PAIR_CHOICE" in
    1) CPU="1"; RAM="2Gi" ;;
    3) CPU="4"; RAM="8Gi" ;;
    *) CPU="2"; RAM="4Gi" ;;
esac

if [ -f "nginx.conf" ]; then
    sed -i "s|CLEAN_DECOY|$CLEAN_DECOY|g" nginx.conf
    echo -e "${GREEN}Decoy host mask bound to: $CLEAN_DECOY${RESET}"
else
    echo -e "${RED}FATAL ERROR: nginx.conf missing from working directory!${RESET}"
    exit 1
fi

echo -e "\n${CYAN} Initiating Google Cloud Containerization Engine...${RESET}"

loading "Compiling Container Environment (Cloud Build)"
gcloud builds submit --tag "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" . --quiet > build.log 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}Container compilation phase failed! See build.log below:${RESET}"
    tail -n 15 build.log
    exit 1
fi

loading "Provisioning Low-Latency Serverless Core on Cloud Run"
gcloud run deploy "$SERVICE_NAME" \
  --image "gcr.io/${PROJECT_ID}/${SERVICE_NAME}" \
  --platform managed \
  --region us-central1 \
  --cpu "$CPU" \
  --memory "$RAM" \
  --port 8080 \
  --concurrency 1000 \
  --cpu-boost \
  --no-cpu-throttling \
  --timeout 3600 \
  --min-instances 1 \
  --max-instances 4 \
  --allow-unauthenticated \
  --quiet > deploy.log 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Deployment execution failed! See deploy.log below:${RESET}"
    tail -n 15 deploy.log
    exit 1
fi

SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" --region us-central1 --format='value(status.url)' 2>/dev/null)
CLEAN_HOST=$(echo "$SERVICE_URL" | sed 's|https://||')

echo -e "\n${BLUE}────────────────────────────────────────────────────${RESET}"
echo -e "${GREEN}  (⁠ﾉ⁠◕⁠ヮ⁠◕⁠)⁠ﾉ⁠*⁠.⁠✧ DEPLOYED SUCCESSFULLY TO US REGION${RESET}"
echo -e "${CYAN} ACCESS HOST: ${GREEN}${SERVICE_URL}${RESET}"
echo -e "${BLUE}────────────────────────────────────────────────────${RESET}"

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}                    PROTOCOL & CREDENTIALS${RESET}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${CYAN}  PROTOCOL     | USERNAME/PASSWORD  | WS PATH            | HTTPUPGRADE PATH${RESET}"
echo -e "${YELLOW}  ─────────────────────────────────────────────────────────────────────${RESET}"
echo -e "  ${GREEN}TROJAN${RESET}       | ${GREEN}saeka${RESET}             | ${CYAN}/saeka-tojirp${RESET}  | ${CYAN}/saeka${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}  HOST: ${GREEN}${CLEAN_HOST}${RESET}"
echo -e "${CYAN}  PORT: ${GREEN}443${RESET}"
echo -e "${CYAN}  SNI:  ${GREEN}fcmtoken.googleapis.com${RESET}"
echo -e "${CYAN}  ALPN: ${GREEN}h2${RESET}"
echo -e "${CYAN}  FP:   ${GREEN}chrome${RESET}"
echo -e "${CYAN}  ENCRYPTION: ${GREEN}tls${RESET}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}  CONNECTION CONFIG URI${RESET}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${GREEN}WebSocket (WS):${RESET}"
echo -e "${CYAN}trojan://saeka@${CLEAN_HOST}:443?security=tls&sni=fcmtoken.googleapis.com&type=ws&path=%2Fsaeka-tojirp&host=${CLEAN_HOST}&alpn=h2&fp=chrome#Trojan-WS${RESET}"
echo ""
echo -e "${GREEN}HTTPUpgrade (HU):${RESET}"
echo -e "${CYAN}trojan://saeka@${CLEAN_HOST}:443?security=tls&sni=fcmtoken.googleapis.com&type=httpupgrade&path=%2Fsaeka%3Fed%3D1280&host=${CLEAN_HOST}&alpn=h2&fp=chrome#Trojan-HU${RESET}"
echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

rm -f build.log deploy.log
