# M3U8 Downloader para Android/Termux

Script completo em Bash para gerenciar playlists M3U8 (IPTV) no Termux (Android).

## 📋 Funcionalidades

- **Menu interativo com Figlet** - Interface visual bonita
- **Download direto de URL** - Baixa qualquer playlist M3U8
- **Buscador automático** - Varre GitHub/sites por listas públicas
- **Listas IPTV prontas** - 25+ fontes testadas (IPTV-Org, Brasil, Categorias)
- **Verificação de canais ON/OFF** - Testa todos os streams com ffmpeg
- **Backup/Restauração** - Sistema de versionamento automático
- **Conversão para M3U simples** - Remove metadados, mantém só URLs
- **Teste rápido com ffmpeg** - Valida streams individuais

## 🔧 Pré-requisitos

```bash
pkg install figlet curl ffmpeg
```

Opcional (para abrir pasta no gerenciador de arquivos):
```bash
pkg install termux-api
```

## 📦 Instalação

```bash
# Clone o repositório
git clone https://github.com/SEU_USUARIO/m3u8_downloader.git
cd m3u8_downloader

# Torne executável
chmod +x m3u8_downloader.sh

# Execute
./m3u8_downloader.sh
```

Ou baixe direto:
```bash
curl -O https://raw.githubusercontent.com/SEU_USUARIO/m3u8_downloader/main/m3u8_downloader.sh
chmod +x m3u8_downloader.sh
./m3u8_downloader.sh
```

## 🚀 Como Usar

### 1. Execução Direta
```bash
./m3u8_downloader.sh
```

### 2. Menu Principal
```
══════════════════════ MENU PRINCIPAL ══════════════════════
 1) Baixar nova playlist        - Download de URL M3U8
 2) Buscador automático         - 🔍 Varre GitHub/sites por listas
 3) Listas IPTV prontas         - Fontes públicas populares
 4) Ver playlist atual          - Mostra canais da playlist salva
 5) Limpar playlist             - Remove playlist atual
 6) Fazer backup                - Salva cópia com timestamp
 7) Restaurar backup            - Lista e restaura backups
 8) Testar playlist (ffmpeg)    - Verifica se streams funcionam
 9) Converter para M3U simples  - Remove metadados, só URLs
10) Abrir pasta de downloads    - Navega no gerenciador de arquivos
11) Configurações               - Altera pasta/URL padrão
12) Verificar canais ON/OFF     - Testa TODOS canais online/offline
 0) Sair
```

### 3. Fluxos Principais

#### **Baixar playlist direta (Opção 1)**
- Digite a URL completa (http:// ou https://)
- Faz backup automático da playlist anterior
- Salva em `~/storage/downloads/m3u8_playlists/playlist.m3u8`

#### **Buscador automático (Opção 2)**
- Busca em 7 fontes confiáveis:
  - IPTV-Org países/categorias/idiomas
  - Awesome IPTV (listas curadas)
  - Canaistv (Brasil - único repo BR ativo 2026)
  - FreetuxTV
- Paginação de resultados
- Opção de baixar individual ou merge de todas

#### **Listas IPTV prontas (Opção 3) - ⭐ RECOMENDADO**
25 fontes testadas e funcionando:
- **Globais**: IPTV-Org Global (18k+ canais), por categoria
- **Brasil**: 456 canais (br.m3u), Samsung TV+, Pluto TV
- **Categorias**: Notícias, Filmes, Esportes, Música, Kids, etc.
- **Canais abertos BR**: Band, Record, RedeTV, SBT, CNN, ESPN, GloboNews

#### **Verificar canais ON/OFF (Opção 12)**
- Testa TODOS canais da playlist
- Timeout de 3s por canal (rápido)
- Mostra contador: ONLINE / OFFLINE / Total
- Suporta Ctrl+C para interromper

## 📁 Estrutura de Arquivos

```
~/storage/downloads/m3u8_playlists/
├── playlist.m3u8           # Playlist atual
├── playlist_simple.m3u     # Versão simplificada (opção 9)
└── backups/
    ├── playlist_20261110_143000.m3u8
    ├── playlist_backup_20261110_143000.m3u8
    └── playlist_deleted_20261110_143000.m3u8
```

## ⚙️ Configurações (Opção 11)

- Altera pasta de download
- Backups seguem automaticamente a pasta de downloads

## 🎯 Dicas de Uso

| Ação | Como fazer |
|------|------------|
| Usar no IPTV Player | Copie `playlist.m3u8` ou `playlist_simple.m3u` |
| Atualizar canais BR | Use opção 3 → 16 (Brasil Geral - 456 canais) |
| Só canais de esportes | Opção 3 → 9 (Sports) ou 24 (ESPN Brasil) |
| Testar se funciona | Opção 8 (rápido, 5 streams) ou 12 (completo) |
| Recuperar playlist antiga | Opção 7 (restaurar backup) |
| Limpar tudo | Opção 5 (confirma com "SIM") |

## 🔗 Fontes Principais (2026 - Testadas)

| Fonte | Status | Descrição |
|-------|--------|-----------|
| **IPTV-Org** | ✅ Ativo | Principal - 18k+ canais, atualizado diariamente |
| **Canaistv** | ✅ Ativo | Único repo Brasil ativo verificado 2026 |
| **FreetuxTV** | ✅ Ativo | Listas europeias/Brasil |
| **Awesome IPTV** | ✅ Ativo | Listas curadas pela comunidade |

## ⚠️ Avisos Legais

- Este script apenas **baixa e organiza** playlists públicas
- Não hospeda nem distribui conteúdo protegido
- Use apenas streams de domínio público / canais abertos
- Respeite direitos autorais e termos de uso de cada fonte
- IPTV-Org mantém apenas canais de domínio público

## 🐛 Solução de Problemas

| Problema | Solução |
|----------|---------|
| `figlet: not found` | `pkg install figlet` |
| `ffmpeg: not found` | `pkg install ffmpeg` |
| Download falha | Verifique conexão / URL válida |
| Canais OFFLINE | Normal - streams públicos caem frequentemente |
| Permissão negada | `chmod +x m3u8_downloader.sh` |
| Termux não acessa storage | `termux-setup-storage` |

## 📄 Licença

MIT - Use livremente, modifique, compartilhe.

---

**Desenvolvido para Termux/Android** 📱