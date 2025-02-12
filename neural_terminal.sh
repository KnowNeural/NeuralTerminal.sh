#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Global variables
TAG_FILTER=""
PINNED_TOKENS=()
MAX_DISPLAY=25
SIGNAL_FILTER=""  # Can be "long" or "short"

# Function to show help message
show_help() {
    echo -e "${BOLD}Usage:${NC}"
    echo "  $0 [options]"
    echo
    echo -e "${BOLD}Options:${NC}"
    echo "  -t, --tag TAG       Filter by tag (e.g., 'drift', 'gfm')"
    echo "  -p, --pin SYMBOL    Pin a token to the top"
    echo "  -u, --unpin SYMBOL  Unpin a token"
    echo "  -l, --list          List pinned tokens"
    echo "  -c, --clear         Clear all filters and pins"
    echo "  -n, --number N      Show N lines (default: 25)"
    echo "  --long              Show only long signals"
    echo "  --short             Show only short signals"
    echo "  -h, --help          Show this help message"
    echo
    echo -e "${BOLD}Interactive Commands:${NC}"
    echo "  Ctrl+C              Exit program"
}

# Function to handle command line arguments
handle_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--tag)
                TAG_FILTER="$2"
                shift 2
                ;;
            -p|--pin)
                PINNED_TOKENS+=("$2")
                echo "Pinned $2 to top"
                shift 2
                ;;
            -u|--unpin)
                for i in "${!PINNED_TOKENS[@]}"; do
                    if [[ "${PINNED_TOKENS[i]}" = "${2^^}" ]]; then
                        unset 'PINNED_TOKENS[i]'
                    fi
                done
                PINNED_TOKENS=("${PINNED_TOKENS[@]}")
                echo "Unpinned ${2^^}"
                shift 2
                ;;
            -l|--list)
                echo "Pinned tokens: ${PINNED_TOKENS[*]}"
                exit 0
                ;;
            -c|--clear)
                PINNED_TOKENS=()
                TAG_FILTER=""
                SIGNAL_FILTER=""
                echo "Cleared all filters and pins"
                shift
                ;;
            --long)
                SIGNAL_FILTER="long"
                shift
                ;;
            --short)
                SIGNAL_FILTER="short"
                shift
                ;;
            -n|--number)
                MAX_DISPLAY="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# handle_keyboard() {
#     :  # No-op
# }

format_number() {
    local num=$1
    local decimals=${2:-2}
    
    if [[ -z "$num" || "$num" == "null" ]]; then
        echo "N/A"
        return
    fi
    
    awk -v num="$num" -v dec="$decimals" 'BEGIN {printf("%.*f\n", dec, num)}'
}

get_color() {
    local value=$1
    
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo -e "${NC}"
        return
    fi
    
    if awk -v val="$value" 'BEGIN { if (val + 0 > 0) exit 0; exit 1}'; then
        echo -e "${GREEN}"
    elif awk -v val="$value" 'BEGIN { if (val + 0 < 0) exit 0; exit 1}'; then
        echo -e "${RED}"
    else
        echo -e "${NC}"
    fi
}

get_signal() {
    local signals=$1
    
    if [[ -z "$signals" || "$signals" == "null" ]]; then
        echo -e "${GRAY}-${NC}"
        return
    fi
    
    local action=$(echo "$signals" | jq -r '.action')
    
    case "$action" in
        *"Long"*)
            echo -e "${GREEN}L${NC}"
            ;;
        *"Short"*)
            echo -e "${RED}S${NC}"
            ;;
        *)
            echo -e "${GRAY}-${NC}"
            ;;
    esac
}

# header
print_header() {
    clear
    printf "${BOLD}%-8s %-12s %-8s %-10s %4s %13s %8s ${NC}\n" \
        "Symbol" "Price" "Signal" "EMA" "RSI" "Change%" "Tags"
    echo "────────────────────────────────────────────────────────────────────────────────"
}


# NO BLCOKING
stty -echo -icanon time 0 min 0

# cleanup
trap 'stty echo icanon' EXIT

handle_args "$@"

while true; do
    # handle_keyboard

    # API 
    response=$(curl -s 'https://www.knowneural.com/api/marketdata')
    
    if ! echo "$response" | jq -e '.success == true' >/dev/null 2>&1; then
        echo "Error: Invalid response from API"
        sleep 5
        continue
    fi
    
    sorted_data=$(echo "$response" | jq -r '
        .data |
        sort_by(if .EMA_trend == null then 0 else (.EMA_trend | fabs) end) |
        reverse
    ')
    
    if [[ -n "$TAG_FILTER" ]]; then
        sorted_data=$(echo "$sorted_data" | jq -r "[.[] | select(.tags | contains(\"$TAG_FILTER\"))]")
    fi
    
    if [[ "$SIGNAL_FILTER" == "long" ]]; then
        sorted_data=$(echo "$sorted_data" | jq -r '[.[] | select(.signals.action | contains("Long"))]')
    elif [[ "$SIGNAL_FILTER" == "short" ]]; then
        sorted_data=$(echo "$sorted_data" | jq -r '[.[] | select(.signals.action | contains("Short"))]')
    fi
    
    print_header
    
    # pinned tokens
    if [[ ${#PINNED_TOKENS[@]} -gt 0 ]]; then
        for symbol in "${PINNED_TOKENS[@]}"; do
            if [[ -n "$symbol" ]]; then
                echo "$sorted_data" | jq -c --arg sym "${symbol^^}" '.[] | select(.symbol | ascii_upcase == $sym)' | while read -r row; do
                    symbol=$(echo "$row" | jq -r '.symbol // "N/A"')
                    price=$(echo "$row" | jq -r '.current_price // "N/A"')
                    ema_trend=$(echo "$row" | jq -r '.EMA_trend // "N/A"')
                    rsi=$(echo "$row" | jq -r '.RSI // "N/A"')
                    price_change=$(echo "$row" | jq -r '.price_change_5min // "N/A"')
                    tags=$(echo "$row" | jq -r '.tags // "N/A"')
                    signals=$(echo "$row" | jq -r '.signals // "N/A"')
                    
                    price_color=$(get_color "$price_change")
                    ema_color=$(get_color "$ema_trend")
                    signal=$(get_signal "$signals")
                    
                    # Format the numbers before printing
                    formatted_price=$(format_number "$price" 8)
                    formatted_ema=$(format_number "$ema_trend" 4)
                    formatted_change=$(format_number "$price_change" 2)

                    printf "%-8s ${price_color}%-15s${NC} %-15s %-12s %-10.2f %-12s %-20s\n" \
                        "$symbol" \
                        "$formatted_price" \
                        "$signal" \
                        "$formatted_ema" \
                        "$rsi" \
                        "${formatted_change}%" \
                        "$tags"
                done
            fi
        done
        echo "────────────────────────────────────────────────────────────────────────────────────────"
    fi
    
    # non-pinned tokens
    remaining_slots=$((MAX_DISPLAY - ${#PINNED_TOKENS[@]}))
    pinned_symbols_json=$(printf '%s\n' "${PINNED_TOKENS[@]}" | jq -R . | jq -s . | tr '[:lower:]' '[:upper:]')
    echo "$sorted_data" | jq -c --argjson pins "$pinned_symbols_json" \
        '.[] | select(.symbol | ascii_upcase as $s | ($pins | index($s)) | not)' | \
        head -n $remaining_slots | while read -r row; do
        symbol=$(echo "$row" | jq -r '.symbol // "N/A"')
        price=$(echo "$row" | jq -r '.current_price // "N/A"')
        ema_trend=$(echo "$row" | jq -r '.EMA_trend // "N/A"')
        rsi=$(echo "$row" | jq -r '.RSI // "N/A"')
        price_change=$(echo "$row" | jq -r '.price_change_5min // "N/A"')
        tags=$(echo "$row" | jq -r '.tags // "N/A"')
        signals=$(echo "$row" | jq -r '.signals // "N/A"')
        
        price_color=$(get_color "$price_change")
        ema_color=$(get_color "$ema_trend")
        signal=$(get_signal "$signals")
        
        # Format the numbers before printing
        formatted_price=$(format_number "$price" 8)
        formatted_ema=$(format_number "$ema_trend" 4)
        formatted_change=$(format_number "$price_change" 2)
        
        printf "%-8s ${price_color}%-15s${NC} %-15s %-12s %-10.2f %-12s %-20s\n" \
            "$symbol" \
            "$formatted_price" \
            "$signal" \
            "$formatted_ema" \
            "$rsi" \
            "${formatted_change}%" \
            "$tags"
    done
    
    # footer
    echo "───────────────────────────────────────────────────────────────────────────────────"
    footer="${GRAY}Last updated: $(date '+%H:%M:%S') | Showing $MAX_DISPLAY by |EMA|"
    [[ "$SIGNAL_FILTER" == "long" ]] && footer+=" | Long signals only"
    [[ "$SIGNAL_FILTER" == "short" ]] && footer+=" | Short signals only"
    [[ -n "$TAG_FILTER" ]] && footer+=" | Tag: $TAG_FILTER"
    [[ ${#PINNED_TOKENS[@]} -gt 0 ]] && footer+=" | Pins: ${PINNED_TOKENS[*]}"
    footer+="${NC}"
    echo -e "$footer"
    echo -e "${YELLOW}Press Ctrl+C to exit${NC}"
    
    sleep 5
done
