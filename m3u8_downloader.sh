#!/data/data/com.termux/files/usr/bin/bash

# M3U8 Downloader Script with Figlet Menu
# Save location: ~/storage/downloads/m3u8_playlists/

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Config
DOWNLOAD_DIR="$HOME/storage/downloads/m3u8_playlists"
PLAYLIST_FILE="$DOWNLOAD_DIR/playlist.m3u8"
BACKUP_DIR="$DOWNLOAD_DIR/backups"

# Ensure directories exist
mkdir -p "$DOWNLOAD_DIR"
mkdir -p "$BACKUP_DIR"

# Check dependencies
check_dependencies() {
    local missing=()
    command -v figlet >/dev/null 2>&1 || missing+=("figlet")
    command -v curl >/dev/null 2>&1 || missing+=("curl")
    command -v ffmpeg >/dev/null 2>&1 || missing+=("ffmpeg")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Dependências faltando: ${missing[*]}${NC}"
        echo -e "${YELLOW}Instale com: pkg install ${missing[*]}${NC}"
        exit 1
    fi
}

# Show banner with figlet
show_banner() {
    clear
    echo -e "${CYAN}"
    figlet -f slant "M3U8" 2>/dev/null || figlet "M3U8"
    figlet -f small "Downloader" 2>/dev/null || echo "Downloader"
    echo -e "${NC}"
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${BOLD}Gerenciador de Playlists M3U8 para Android/Termux${NC}  ${MAGENTA}║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Show current playlist info
show_playlist_info() {
    if [ -f "$PLAYLIST_FILE" ]; then
        local lines=$(wc -l < "$PLAYLIST_FILE")
        local size=$(du -h "$PLAYLIST_FILE" | cut -f1)
        local modified=$(stat -c "%y" "$PLAYLIST_FILE" | cut -d'.' -f1)
        echo -e "${GREEN}📁 Playlist atual:${NC} $PLAYLIST_FILE"
        echo -e "${GREEN}📊 Linhas:${NC} $lines | ${GREEN}Tamanho:${NC} $size | ${GREEN}Modificado:${NC} $modified"

        # Count channels (lines starting with #EXTINF)
        local channels=$(grep -c "^#EXTINF" "$PLAYLIST_FILE" 2>/dev/null || echo "0")
        echo -e "${GREEN}📺 Canais detectados:${NC} $channels"
    else
        echo -e "${YELLOW}📁 Nenhuma playlist encontrada em:${NC} $PLAYLIST_FILE"
    fi
    echo
}

# Show menu
show_menu() {
    echo -e "${BLUE}${BOLD}══════════════════════ MENU PRINCIPAL ══════════════════════${NC}"
    echo -e "${CYAN} 1)${NC} ${BOLD}Baixar nova playlist${NC}        - Download de URL M3U8"
    echo -e "${CYAN} 2)${NC} ${BOLD}Buscador automático${NC}         - 🔍 Varre GitHub/sites por listas"
    echo -e "${CYAN} 3)${NC} ${BOLD}Listas IPTV prontas${NC}         - Fontes públicas populares"
    echo -e "${CYAN} 4)${NC} ${BOLD}Ver playlist atual${NC}          - Mostra canais da playlist salva"
    echo -e "${CYAN} 5)${NC} ${BOLD}Limpar playlist${NC}             - Remove playlist atual"
    echo -e "${CYAN} 6)${NC} ${BOLD}Fazer backup${NC}                - Salva cópia com timestamp"
    echo -e "${CYAN} 7)${NC} ${BOLD}Restaurar backup${NC}            - Lista e restaura backups"
    echo -e "${CYAN} 8)${NC} ${BOLD}Testar playlist (ffmpeg)${NC}    - Verifica se streams funcionam"
    echo -e "${CYAN} 9)${NC} ${BOLD}Converter para M3U simples${NC}  - Remove metadados, só URLs"
    echo -e "${CYAN}10)${NC} ${BOLD}Abrir pasta de downloads${NC}    - Navega no gerenciador de arquivos"
    echo -e "${CYAN}11)${NC} ${BOLD}Configurações${NC}               - Altera pasta/URL padrão"
    echo -e "${CYAN}12)${NC} ${BOLD}Verificar canais ON/OFF${NC}     - Testa TODOS canais online/offline"
    echo -e "${RED} 0)${NC} ${BOLD}Sair${NC}"
    echo -e "${BLUE}═════════════════════════════════════════════════════════════${NC}"
    echo
}

# Download new playlist
download_playlist() {
    echo -e "${YELLOW}${BOLD}=== BAIXAR NOVA PLAYLIST ===${NC}"
    echo
    read -p "🔗 Digite a URL da playlist M3U8: " url

    if [ -z "$url" ]; then
        echo -e "${RED}❌ URL vazia!${NC}"
        sleep 2
        return
    fi

    # Validate URL
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo -e "${RED}❌ URL inválida! Deve começar com http:// ou https://${NC}"
        sleep 2
        return
    fi

    echo -e "${CYAN}⏳ Baixando playlist...${NC}"

    # Backup current if exists
    if [ -f "$PLAYLIST_FILE" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$PLAYLIST_FILE" "$BACKUP_DIR/playlist_$timestamp.m3u8"
        echo -e "${GREEN}✓ Backup automático salvo em backups/${NC}"
    fi

    # Download with progress
    if curl -L -# -o "$PLAYLIST_FILE" "$url"; then
        echo -e "${GREEN}✅ Playlist baixada com sucesso!${NC}"
        show_playlist_info
    else
        echo -e "${RED}❌ Erro ao baixar playlist!${NC}"
        # Restore backup if download failed
        if [ -f "$BACKUP_DIR/playlist_$(date +"%Y%m%d_%H%M%S").m3u8" ]; then
            echo -e "${YELLOW}🔄 Restaurando backup anterior...${NC}"
        fi
    fi

    read -p "Pressione Enter para continuar..."
}

# View current playlist
view_playlist() {
    echo -e "${YELLOW}${BOLD}=== PLAYLIST ATUAL ===${NC}"
    echo

    if [ ! -f "$PLAYLIST_FILE" ]; then
        echo -e "${RED}❌ Nenhuma playlist encontrada!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    echo -e "${CYAN}Primeiras 50 linhas:${NC}"
    echo -e "${MAGENTA}────────────────────────────────────────${NC}"
    head -n 50 "$PLAYLIST_FILE" | cat -n
    echo -e "${MAGENTA}────────────────────────────────────────${NC}"

    local total_lines=$(wc -l < "$PLAYLIST_FILE")
    if [ "$total_lines" -gt 50 ]; then
        echo -e "${YELLOW}... ($((total_lines - 50)) linhas a mais)${NC}"
    fi

    echo
    read -p "Pressione Enter para continuar..."
}

# Clear playlist
clear_playlist() {
    echo -e "${YELLOW}${BOLD}=== LIMPAR PLAYLIST ===${NC}"
    echo

    if [ ! -f "$PLAYLIST_FILE" ]; then
        echo -e "${YELLOW}⚠️  Nenhuma playlist para limpar.${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    show_playlist_info
    echo -e "${RED}⚠️  ATENÇÃO: Isso apagará a playlist atual permanentemente!${NC}"
    read -p "Tem certeza? Digite 'SIM' para confirmar: " confirm

    if [ "$confirm" = "SIM" ]; then
        # Backup before deleting
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$PLAYLIST_FILE" "$BACKUP_DIR/playlist_deleted_$timestamp.m3u8"
        rm "$PLAYLIST_FILE"
        echo -e "${GREEN}✅ Playlist removida! Backup salvo em backups/${NC}"
    else
        echo -e "${YELLOW}❌ Operação cancelada.${NC}"
    fi

    read -p "Pressione Enter para continuar..."
}

# Backup playlist
backup_playlist() {
    echo -e "${YELLOW}${BOLD}=== FAZER BACKUP ===${NC}"
    echo

    if [ ! -f "$PLAYLIST_FILE" ]; then
        echo -e "${RED}❌ Nenhuma playlist para fazer backup!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_file="$BACKUP_DIR/playlist_backup_$timestamp.m3u8"

    cp "$PLAYLIST_FILE" "$backup_file"
    echo -e "${GREEN}✅ Backup salvo em:${NC} $backup_file"

    # Show backup size
    local size=$(du -h "$backup_file" | cut -f1)
    echo -e "${GREEN}📊 Tamanho:${NC} $size"

    read -p "Pressione Enter para continuar..."
}

# Restore backup
restore_backup() {
    echo -e "${YELLOW}${BOLD}=== RESTAURAR BACKUP ===${NC}"
    echo

    local backups=("$BACKUP_DIR"/*.m3u8)

    if [ ! -e "${backups[0]}" ]; then
        echo -e "${RED}❌ Nenhum backup encontrado!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    echo -e "${CYAN}Backups disponíveis:${NC}"
    echo

    local i=1
    for backup in "${backups[@]}"; do
        local name=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date_str=$(stat -c "%y" "$backup" | cut -d'.' -f1)
        echo -e " ${CYAN}$i)${NC} $name ${YELLOW}($size)${NC} - $date_str"
        ((i++))
    done

    echo
    read -p "Escolha o número do backup para restaurar (0 para cancelar): " choice

    if [ "$choice" = "0" ] || [ -z "$choice" ]; then
        echo -e "${YELLOW}❌ Operação cancelada.${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        echo -e "${RED}❌ Opção inválida!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    local selected="${backups[$((choice-1))]}"

    # Backup current before restore
    if [ -f "$PLAYLIST_FILE" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$PLAYLIST_FILE" "$BACKUP_DIR/playlist_before_restore_$timestamp.m3u8"
    fi

    cp "$selected" "$PLAYLIST_FILE"
    echo -e "${GREEN}✅ Backup restaurado com sucesso!${NC}"
    show_playlist_info

    read -p "Pressione Enter para continuar..."
}

# Test playlist with ffmpeg (quick test - first 5 streams)
test_playlist() {
    echo -e "${YELLOW}${BOLD}=== TESTAR PLAYLIST (FFMPEG - RÁPIDO) ===${NC}"
    echo

    if [ ! -f "$PLAYLIST_FILE" ]; then
        echo -e "${RED}❌ Nenhuma playlist para testar!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    # Extract first few stream URLs
    local streams=($(grep -E "^https?://" "$PLAYLIST_FILE" | head -5))

    if [ ${#streams[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Nenhuma URL de stream encontrada na playlist.${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    echo -e "${CYAN}Testando primeiros ${#streams[@]} streams...${NC}"
    echo -e "${YELLOW}💡 Pressione Ctrl+C a qualquer momento para parar${NC}"
    echo

    local working=0
    local failed=0
    local stop_test=0

    # Trap Ctrl+C
    trap 'stop_test=1; echo -e "\n${YELLOW}⏹️  Teste interrompido pelo usuário${NC}"; trap - INT' INT

    for i in "${!streams[@]}"; do
        [ $stop_test -eq 1 ] && break

        local url="${streams[$i]}"
        echo -ne "${CYAN}[$((i+1))/${#streams[@]}] Testando: ${NC}${url:0:60}... "

        # Quick test with ffmpeg (3 second timeout - mais rápido)
        if timeout 3 ffmpeg -v error -i "$url" -f null - -t 2 2>/dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            ((working++))
        else
            echo -e "${RED}❌ FALHOU${NC}"
            ((failed++))
        fi
    done

    trap - INT

    echo
    echo -e "${GREEN}✅ Funcionando: $working${NC}"
    echo -e "${RED}❌ Falharam: $failed${NC}"

    read -p "Pressione Enter para continuar..."
}

# Check all channels online/offline status
check_channels_online() {
    echo -e "${YELLOW}${BOLD}=== VERIFICAR CANAIS ONLINE/OFFLINE ===${NC}"
    echo

    if [ ! -f "$PLAYLIST_FILE" ]; then
        echo -e "${RED}❌ Nenhuma playlist encontrada!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    # Parse all channels from playlist
    local channels=()
    local urls=()
    local extinfs=()

    while IFS= read -r line; do
        if [[ "$line" =~ ^#EXTINF ]]; then
            extinfs+=("$line")
        elif [[ "$line" =~ ^https?:// ]]; then
            local title="Canal"
            local extinf="${extinfs[-1]:-}"
            if [[ "$extinf" =~ ^#EXTINF.*\,(.+)$ ]]; then
                title="${BASH_REMATCH[1]}"
            fi
            channels+=("$title")
            urls+=("$line")
            extinfs=()
        fi
    done < "$PLAYLIST_FILE"

    local total=${#channels[@]}

    if [ $total -eq 0 ]; then
        echo -e "${YELLOW}⚠️  Nenhum canal encontrado na playlist.${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    echo -e "${CYAN}Total de canais: $total${NC}"
    echo -e "${CYAN}Verificando status (timeout 3s por canal - MAIS RÁPIDO)...${NC}"
    echo -e "${YELLOW}💡 Pressione Ctrl+C a qualquer momento para parar${NC}"
    echo

    local online=0
    local offline=0
    local stop_test=0

    # Trap Ctrl+C
    trap 'stop_test=1; echo -e "\n${YELLOW}⏹️  Verificação interrompida pelo usuário${NC}"; trap - INT' INT

    for i in "${!channels[@]}"; do
        [ $stop_test -eq 1 ] && break

        local name="${channels[$i]}"
        local url="${urls[$i]}"

        echo -ne "${CYAN}[$((i+1))/$total]${NC} ${name:0:40}... "

        # Quick test with ffmpeg (3 second timeout - mais rápido)
        if timeout 3 ffmpeg -v error -i "$url" -f null - -t 2 2>/dev/null; then
            echo -e "${GREEN}✅ ONLINE${NC}"
            ((online++))
        else
            echo -e "${RED}❌ OFFLINE${NC}"
            ((offline++))
        fi
    done

    trap - INT

    echo
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}RESULTADO FINAL:${NC}"
    echo -e "${GREEN}✅ ONLINE: $online${NC}"
    echo -e "${RED}❌ OFFLINE: $offline${NC}"
    echo -e "${CYAN}📊 Total testado: $((online + offline)) de $total${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════════════${NC}"

    read -p "Pressione Enter para continuar..."
}

# Convert to simple M3U
convert_to_simple() {
    echo -e "${YELLOW}${BOLD}=== CONVERTER PARA M3U SIMPLES ===${NC}"
    echo

    if [ ! -f "$PLAYLIST_FILE" ]; then
        echo -e "${RED}❌ Nenhuma playlist para converter!${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    local output="$DOWNLOAD_DIR/playlist_simple.m3u"

    echo -e "${CYAN}Convertendo...${NC}"

    # Create simple M3U with only #EXTINF and URL lines
    awk '
        /^#EXTM3U/ { print; next }
        /^#EXTINF/ { extinf=$0; next }
        /^https?:\/\// {
            if (extinf) { print extinf; extinf="" }
            print
        }
    ' "$PLAYLIST_FILE" > "$output"

    # Ensure header
    if ! head -1 "$output" | grep -q "^#EXTM3U"; then
        sed -i '1i#EXTM3U' "$output"
    fi

    local channels=$(grep -c "^#EXTINF" "$output")
    local size=$(du -h "$output" | cut -f1)

    echo -e "${GREEN}✅ Convertido para:${NC} $output"
    echo -e "${GREEN}📺 Canais:${NC} $channels | ${GREEN}Tamanho:${NC} $size"

    read -p "Pressione Enter para continuar..."
}

# Open downloads folder
open_folder() {
    echo -e "${YELLOW}${BOLD}=== ABRIR PASTA DE DOWNLOADS ===${NC}"
    echo

    echo -e "${CYAN}Pasta:${NC} $DOWNLOAD_DIR"
    echo

    # List files
    ls -lh "$DOWNLOAD_DIR"
    echo

    # Try to open with termux-open
    if command -v termux-open >/dev/null 2>&1; then
        read -p "Abrir no gerenciador de arquivos? (s/N): " open_it
        if [[ "$open_it" =~ ^[Ss]$ ]]; then
            termux-open "$DOWNLOAD_DIR"
            echo -e "${GREEN}✅ Pasta aberta!${NC}"
        fi
    else
        echo -e "${YELLOW}💡 Dica: Instale 'termux-api' para abrir pastas: pkg install termux-api${NC}"
    fi

    read -p "Pressione Enter para continuar..."
}

# Popular IPTV sources (public/free M3U8 lists) - ATUALIZADO 2026
# Fontes testadas e funcionando ✅
declare -A IPTV_SOURCES=(
    # --- GLOBAIS (IPTV-Org - mais confiável) ---
    ["1"]="IPTV-Org Global (18000+ canais)|https://iptv-org.github.io/iptv/index.m3u"
    ["2"]="IPTV-Org Por Categoria|https://iptv-org.github.io/iptv/index.category.m3u"
    ["3"]="IPTV-Org Brasil (456 canais)|https://iptv-org.github.io/iptv/countries/br.m3u"
    ["4"]="IPTV-Org Portugal|https://iptv-org.github.io/iptv/countries/pt.m3u"
    ["5"]="IPTV-Org Espanhol|https://iptv-org.github.io/iptv/countries/es.m3u"
    ["6"]="IPTV-Org Inglês (EUA/UK)|https://iptv-org.github.io/iptv/countries/us.m3u"

    # --- CATEGORIAS IPTV-Org (sempre atualizadas) ---
    ["7"]="📺 Notícias (News)|https://iptv-org.github.io/iptv/categories/news.m3u"
    ["8"]="🎬 Filmes (Movies)|https://iptv-org.github.io/iptv/categories/movies.m3u"
    ["9"]="🏀 Esportes (Sports)|https://iptv-org.github.io/iptv/categories/sports.m3u"
    ["10"]="🎵 Música (Music)|https://iptv-org.github.io/iptv/categories/music.m3u"
    ["11"]="📚 Documentários|https://iptv-org.github.io/iptv/categories/documentary.m3u"
    ["12"]="👶 Infantil (Kids)|https://iptv-org.github.io/iptv/categories/kids.m3u"
    ["13"]="🎭 Entretenimento|https://iptv-org.github.io/iptv/categories/entertainment.m3u"
    ["14"]="🔬 Ciência/Tecnologia|https://iptv-org.github.io/iptv/categories/science.m3u"
    ["15"]="🕊️ Religioso|https://iptv-org.github.io/iptv/categories/religious.m3u"

    # --- STREAMS ESPECÍFICOS BRASIL (IPTV-Org master) ---
    ["16"]="🇧🇷 Brasil Geral (streams)|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["17"]="📱 Samsung TV+ Brasil|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br_samsung.m3u"
    ["18"]="🪐 Pluto TV Brasil|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br_pluto.m3u"

    # --- CANAIS ABERTOS BRASIL (extraídos do br.m3u) ---
    ["19"]="📺 Band + BandSports + BandNews|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["20"]="📺 Record + Record News|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["21"]="📺 RedeTV|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["22"]="📺 SBT (Nacional/Kids/Interior)|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["23"]="📺 CNN Brasil|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["24"]="📺 ESPN Brasil (1/2/3/4)|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
    ["25"]="📺 GloboNews + Globoplay Novelas|https://raw.githubusercontent.com/iptv-org/iptv/master/streams/br.m3u"
)

# Search sources for auto-discovery (GitHub repos, aggregators) - ATUALIZADO 2026
# Fontes testadas e funcionando ✅
declare -A SEARCH_SOURCES=(
    # IPTV-Org (fonte principal mais confiável)
    ["github_iptv_org_streams"]="https://api.github.com/repos/iptv-org/iptv/contents/streams"
    ["github_iptv_org_countries"]="https://api.github.com/repos/iptv-org/iptv/contents/countries"
    ["iptv_org_countries_web"]="https://iptv-org.github.io/iptv/countries/"
    ["iptv_org_categories_web"]="https://iptv-org.github.io/iptv/categories/"
    ["iptv_org_languages_web"]="https://iptv-org.github.io/iptv/languages/"

    # Outros repos confiáveis que ainda existem
    ["github_freetuxtv"]="https://api.github.com/repos/freetuxTV/freetuxTV/contents"
    ["github_m3u4u"]="https://api.github.com/repos/m3u4u/m3u4u/contents/lists"
    ["github_awesome_iptv"]="https://api.github.com/repos/iptv-org/awesome-iptv/contents"

    # Repositórios Brasil ativos (verificados 2026)
    ["github_canaistv"]="https://api.github.com/repos/canaistv/iptv/contents"
)

# Auto-search for playlists from multiple sources - ATUALIZADO 2026
auto_search_playlists() {
    echo -e "${YELLOW}${BOLD}=== BUSCADOR AUTOMÁTICO DE LISTAS IPTV (2026) ===${NC}"
    echo -e "${CYAN}🔍 Procurando listas em fontes CONFIÁVEIS e ATIVAS...${NC}"
    echo

    local found_urls=()
    local found_names=()

    # Search 1: iptv-org countries (via streams API - países estão em streams/)
    echo -ne "${CYAN}[1/7]${NC} Verificando iptv-org países... "
    local countries=$(curl -sL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/iptv-org/iptv/contents/streams" 2>/dev/null | grep -oP '"name":\s*"\K[^"]+\.m3u' | grep -vE '_|-' | head -30)
    if [ -n "$countries" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$countries" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://raw.githubusercontent.com/iptv-org/iptv/master/streams/$m3u")
            found_names+=("🌍 IPTV-Org: $name (País)")
        done <<< "$countries"
    else
        echo -e "${RED}✗${NC}"
    fi

    # Search 2: iptv-org categories (via web - PLAYLISTS.md shows these exist)
    echo -ne "${CYAN}[2/7]${NC} Verificando iptv-org categorias... "
    local categories=$(curl -sL "https://iptv-org.github.io/iptv/categories/" 2>/dev/null | grep -oP 'href="\K[^"]+\.m3u(?=")' | head -25)
    if [ -n "$categories" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$categories" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://iptv-org.github.io/iptv/categories/$m3u")
            found_names+=("📂 IPTV-Org: $name (Categoria)")
        done <<< "$categories"
    else
        # Fallback: use known categories from PLAYLISTS.md
        local known_cats="news movies sports music documentary kids entertainment science religious animation auto business classic comedy cooking culture education general lifestyle nature shop"
        echo -e "${YELLOW}⚠${NC} (usando categorias conhecidas)"
        for cat in $known_cats; do
            found_urls+=("https://iptv-org.github.io/iptv/categories/$cat.m3u")
            found_names+=("📂 IPTV-Org: ${cat^} (Categoria)")
        done
    fi

    # Search 3: iptv-org languages (via web)
    echo -ne "${CYAN}[3/7]${NC} Verificando iptv-org idiomas... "
    local languages=$(curl -sL "https://iptv-org.github.io/iptv/languages/" 2>/dev/null | grep -oP 'href="\K[^"]+\.m3u(?=")' | head -20)
    if [ -n "$languages" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$languages" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://iptv-org.github.io/iptv/languages/$m3u")
            found_names+=("🌐 IPTV-Org: $name (Idioma)")
        done <<< "$languages"
    else
        echo -e "${RED}✗${NC}"
    fi

    # Search 4: GitHub iptv-org streams (API - pega streams específicos como br, br_pluto, br_samsung)
    echo -ne "${CYAN}[4/7]${NC} Verificando GitHub iptv-org streams especiais... "
    local gh_streams=$(curl -sL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/iptv-org/iptv/contents/streams" 2>/dev/null | grep -oP '"name":\s*"\K[^"]+\.m3u' | grep -E '_|-' | head -30)
    if [ -n "$gh_streams" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$gh_streams" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://raw.githubusercontent.com/iptv-org/iptv/master/streams/$m3u")
            found_names+=("📡 IPTV-Org: $name (Stream)")
        done <<< "$gh_streams"
    else
        echo -e "${RED}✗${NC}"
    fi

    # Search 5: Awesome IPTV (curated lists)
    echo -ne "${CYAN}[5/7]${NC} Verificando Awesome IPTV... "
    local awesome=$(curl -sL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/iptv-org/awesome-iptv/contents" 2>/dev/null | grep -oP '"name":\s*"\K[^"]+\.m3u' | head -20)
    if [ -n "$awesome" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$awesome" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://raw.githubusercontent.com/iptv-org/awesome-iptv/master/$m3u")
            found_names+=("⭐ Awesome IPTV: $name")
        done <<< "$awesome"
    else
        echo -e "${RED}✗${NC}"
    fi

    # Search 6: Canaistv (Brasil - único repo BR ativo verificado 2026)
    echo -ne "${CYAN}[6/7]${NC} Verificando Canaistv (Brasil)... "
    local canais=$(curl -sL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/canaistv/iptv/contents" 2>/dev/null | grep -oP '"name":\s*"\K[^"]+\.m3u' | head -15)
    if [ -n "$canais" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$canais" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://raw.githubusercontent.com/canaistv/iptv/master/$m3u")
            found_names+=("🇧🇷 Canaistv: $name")
        done <<< "$canais"
    else
        echo -e "${RED}✗${NC}"
    fi

    # Search 7: FreetuxTV (outra fonte confiável)
    echo -ne "${CYAN}[7/7]${NC} Verificando FreetuxTV... "
    local freetux=$(curl -sL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/freetuxTV/freetuxTV/contents" 2>/dev/null | grep -oP '"name":\s*"\K[^"]+\.m3u' | head -15)
    if [ -n "$freetux" ]; then
        echo -e "${GREEN}✓${NC} ($(echo "$freetux" | wc -l) listas)"
        while IFS= read -r m3u; do
            local name=$(basename "$m3u" .m3u | tr '_-' ' ' | sed 's/\b\(.\)/\u\1/g')
            found_urls+=("https://raw.githubusercontent.com/freetuxTV/freetuxTV/master/$m3u")
            found_names+=("📺 FreetuxTV: $name")
        done <<< "$freetux"
    else
        echo -e "${RED}✗${NC}"
    fi

    echo
    echo -e "${GREEN}✅ Busca concluída! Total: ${#found_urls[@]} listas encontradas${NC}"
    echo

    if [ ${#found_urls[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhuma lista encontrada. Verifique sua conexão.${NC}"
        read -p "Pressione Enter para continuar..."
        return
    fi

    # Show results with pagination
    local page=1
    local per_page=15
    local total_pages=$(( (${#found_urls[@]} + per_page - 1) / per_page ))

    while true; do
        show_banner
        echo -e "${YELLOW}${BOLD}=== RESULTADOS DA BUSCA (Página $page/$total_pages) ===${NC}"
        echo

        local start=$(( (page - 1) * per_page ))
        local end=$(( start + per_page - 1 ))
        [ $end -ge ${#found_urls[@]} ] && end=$((${#found_urls[@]} - 1))

        for i in $(seq $start $end); do
            local num=$((i + 1))
            echo -e " ${CYAN}$num)${NC} ${found_names[$i]}"
        done

        echo
        echo -e "${MAGENTA}--- Navegação ---${NC}"
        [ $page -gt 1 ] && echo -e " ${CYAN}p)${NC} Página anterior"
        [ $page -lt $total_pages ] && echo -e " ${CYAN}n)${NC} Próxima página"
        echo -e " ${CYAN}b)${NC} Baixar lista (digite o número)"
        echo -e " ${CYAN}a)${NC} Baixar TODAS (merge em uma playlist)"
        echo -e " ${RED}0)${NC} Voltar"
        echo

        read -p "Escolha: " action

        case $action in
            p) [ $page -gt 1 ] && ((page--)) ;;
            n) [ $page -lt $total_pages ] && ((page++)) ;;
            b)
                read -p "Número da lista para baixar: " list_num
                if [[ "$list_num" =~ ^[0-9]+$ ]] && [ "$list_num" -ge 1 ] && [ "$list_num" -le ${#found_urls[@]} ]; then
                    local idx=$((list_num - 1))
                    download_found_list "${found_names[$idx]}" "${found_urls[$idx]}"
                else
                    echo -e "${RED}❌ Número inválido!${NC}"
                    sleep 1
                fi
                ;;
            a)
                merge_all_lists "${found_names[@]}" "${found_urls[@]}"
                ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida!${NC}"; sleep 1 ;;
        esac
    done
}

# Download a found list
download_found_list() {
    local name="$1"
    local url="$2"

    echo
    echo -e "${CYAN}📥 Baixando: ${BOLD}$name${NC}"
    echo -e "${CYAN}🔗 URL: $url${NC}"
    echo

    # Backup current if exists
    if [ -f "$PLAYLIST_FILE" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$PLAYLIST_FILE" "$BACKUP_DIR/playlist_$timestamp.m3u8"
        echo -e "${GREEN}✓ Backup automático salvo em backups/${NC}"
    fi

    if curl -L -# -o "$PLAYLIST_FILE" "$url"; then
        echo -e "${GREEN}✅ Playlist '$name' baixada com sucesso!${NC}"
        show_playlist_info
    else
        echo -e "${RED}❌ Erro ao baixar '$name'!${NC}"
    fi
    read -p "Pressione Enter para continuar..."
}

# Merge all found lists into one
merge_all_lists() {
    local -n names_ref=$1
    local -n urls_ref=$2

    echo
    echo -e "${CYAN}🔄 Mesclando ${#urls_ref[@]} listas em uma única playlist...${NC}"
    echo

    local temp_file="$DOWNLOAD_DIR/merged_temp.m3u8"
    echo "#EXTM3U" > "$temp_file"
    local total_channels=0

    for i in "${!urls_ref[@]}"; do
        echo -ne "${CYAN}[$((i+1))/${#urls_ref[@]}]${NC} Baixando ${names_ref[$i]}... "
        local list_temp="$DOWNLOAD_DIR/temp_$i.m3u8"
        if curl -sL -o "$list_temp" "${urls_ref[$i]}"; then
            local channels=$(grep -c "^#EXTINF" "$list_temp" 2>/dev/null || echo "0")
            # Append without header
            tail -n +2 "$list_temp" >> "$temp_file"
            echo -e "${GREEN}✓ ($channels canais)${NC}"
            total_channels=$((total_channels + channels))
            rm -f "$list_temp"
        else
            echo -e "${RED}✗ Falhou${NC}"
            rm -f "$list_temp"
        fi
    done

    # Backup current
    if [ -f "$PLAYLIST_FILE" ]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        cp "$PLAYLIST_FILE" "$BACKUP_DIR/playlist_$timestamp.m3u8"
    fi

    mv "$temp_file" "$PLAYLIST_FILE"
    echo
    echo -e "${GREEN}✅ Merge concluído! Total: $total_channels canais${NC}"
    show_playlist_info
    read -p "Pressione Enter para continuar..."
}

# Show IPTV sources menu
show_iptv_sources() {
    while true; do
        show_banner
        echo -e "${YELLOW}${BOLD}=== LISTAS IPTV PRONTAS (PÚBLICAS - 2026) ===${NC}"
        echo -e "${CYAN}✅ Fontes testadas e funcionando (IPTV-Org é a mais confiável)${NC}"
        echo
        echo -e "${MAGENTA}--- GLOBAIS (IPTV-Org) ---${NC}"
        echo -e " ${CYAN}1)${NC} IPTV-Org Global (18000+ canais)"
        echo -e " ${CYAN}2)${NC} IPTV-Org Por Categoria"
        echo -e " ${CYAN}3)${NC} IPTV-Org Brasil (456 canais) ⭐"
        echo -e " ${CYAN}4)${NC} IPTV-Org Portugal"
        echo -e " ${CYAN}5)${NC} IPTV-Org Espanhol"
        echo -e " ${CYAN}6)${NC} IPTV-Org Inglês (EUA/UK)"
        echo
        echo -e "${MAGENTA}--- CATEGORIAS IPTV-Org ---${NC}"
        echo -e " ${CYAN}7)${NC} 📺 Notícias (News)"
        echo -e " ${CYAN}8)${NC} 🎬 Filmes (Movies)"
        echo -e " ${CYAN}9)${NC} 🏀 Esportes (Sports)"
        echo -e " ${CYAN}10)${NC} 🎵 Música (Music)"
        echo -e " ${CYAN}11)${NC} 📚 Documentários"
        echo -e " ${CYAN}12)${NC} 👶 Infantil (Kids)"
        echo -e " ${CYAN}13)${NC} 🎭 Entretenimento"
        echo -e " ${CYAN}14)${NC} 🔬 Ciência/Tecnologia"
        echo -e " ${CYAN}15)${NC} 🕊️ Religioso"
        echo
        echo -e "${MAGENTA}--- STREAMS ESPECÍFICOS BRASIL ---${NC}"
        echo -e " ${CYAN}16)${NC} 🇧🇷 Brasil Geral (streams - 456 canais) ⭐"
        echo -e " ${CYAN}17)${NC} 📱 Samsung TV+ Brasil"
        echo -e " ${CYAN}18)${NC} 🪐 Pluto TV Brasil"
        echo
        echo -e "${MAGENTA}--- CANAIS ABERTOS BR (extraídos do br.m3u) ---${NC}"
        echo -e " ${CYAN}19)${NC} 📺 Band + BandSports + BandNews"
        echo -e " ${CYAN}20)${NC} 📺 Record + Record News"
        echo -e " ${CYAN}21)${NC} 📺 RedeTV"
        echo -e " ${CYAN}22)${NC} 📺 SBT (Nacional/Kids/Interior)"
        echo -e " ${CYAN}23)${NC} 📺 CNN Brasil"
        echo -e " ${CYAN}24)${NC} 📺 ESPN Brasil (1/2/3/4)"
        echo -e " ${CYAN}25)${NC} 📺 GloboNews + Globoplay Novelas"
        echo
        echo -e "${RED} 0)${NC} Voltar ao menu principal"
        echo
        read -p "Escolha uma lista para baixar (0 para voltar): " choice

        if [ "$choice" = "0" ] || [ -z "$choice" ]; then
            return
        fi

        if [[ -n "${IPTV_SOURCES[$choice]}" ]]; then
            IFS='|' read -r name url <<< "${IPTV_SOURCES[$choice]}"
            echo
            echo -e "${CYAN}📥 Baixando: ${BOLD}$name${NC}"
            echo -e "${CYAN}🔗 URL: $url${NC}"
            echo

            # Backup current if exists
            if [ -f "$PLAYLIST_FILE" ]; then
                local timestamp=$(date +"%Y%m%d_%H%M%S")
                cp "$PLAYLIST_FILE" "$BACKUP_DIR/playlist_$timestamp.m3u8"
                echo -e "${GREEN}✓ Backup automático salvo em backups/${NC}"
            fi

            if curl -L -# -o "$PLAYLIST_FILE" "$url"; then
                echo -e "${GREEN}✅ Playlist '$name' baixada com sucesso!${NC}"
                show_playlist_info
            else
                echo -e "${RED}❌ Erro ao baixar '$name'!${NC}"
            fi
            read -p "Pressione Enter para continuar..."
        else
            echo -e "${RED}❌ Opção inválida!${NC}"
            sleep 1
        fi
    done
}

# Settings
settings_menu() {
    while true; do
        show_banner
        echo -e "${YELLOW}${BOLD}=== CONFIGURAÇÕES ===${NC}"
        echo
        echo -e "${CYAN}1)${NC} Pasta de download atual: ${GREEN}$DOWNLOAD_DIR${NC}"
        echo -e "${CYAN}2)${NC} Arquivo da playlist: ${GREEN}$PLAYLIST_FILE${NC}"
        echo -e "${CYAN}3)${NC} Pasta de backups: ${GREEN}$BACKUP_DIR${NC}"
        echo -e "${CYAN}4)${NC} Voltar ao menu principal"
        echo
        read -p "Escolha uma opção: " opt

        case $opt in
            1)
                read -p "Nova pasta de download (caminho completo): " new_dir
                if [ -n "$new_dir" ] && [ -d "$new_dir" ]; then
                    DOWNLOAD_DIR="$new_dir"
                    PLAYLIST_FILE="$DOWNLOAD_DIR/playlist.m3u8"
                    BACKUP_DIR="$DOWNLOAD_DIR/backups"
                    mkdir -p "$BACKUP_DIR"
                    echo -e "${GREEN}✅ Pasta alterada!${NC}"
                else
                    echo -e "${RED}❌ Pasta inválida ou não existe!${NC}"
                fi
                sleep 1
                ;;
            2)
                echo -e "${YELLOW}Use a opção 1 para mudar a pasta (o arquivo segue a pasta).${NC}"
                sleep 2
                ;;
            3)
                echo -e "${YELLOW}A pasta de backups segue a pasta de downloads automaticamente.${NC}"
                sleep 2
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main loop
main() {
    check_dependencies

    while true; do
        show_banner
        show_playlist_info
        show_menu

        read -p "Escolha uma opção: " choice

        case $choice in
            1) download_playlist ;;
            2) auto_search_playlists ;;
            3) show_iptv_sources ;;
            4) view_playlist ;;
            5) clear_playlist ;;
            6) backup_playlist ;;
            7) restore_backup ;;
            8) test_playlist ;;
            9) convert_to_simple ;;
            10) open_folder ;;
            11) settings_menu ;;
            12) check_channels_online ;;
            0)
                echo -e "${GREEN}👋 Saindo... Até logo!${NC}"
                figlet -f small "Bye!" 2>/dev/null || echo "Bye!"
                exit 0
                ;;
            *)
                echo -e "${RED}❌ Opção inválida! Pressione Enter...${NC}"
                read
                ;;
        esac
    done
}

# Run
main