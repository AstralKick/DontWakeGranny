#!/bin/sh
# Stages builder chunks into Rojo-synced temp modules (ReplicatedStorage.Config._SMB1.._SMBn) so Studio can loadstring
# them in order; 'clean' removes them. Usage: map_stmildreds_run.sh 01_site 02_masonry ...   (prefix map_stmildreds_ implied)
cd "$(dirname "$0")/.."
rm -f Game/Config/_SMB*.luau
if [ "$1" = "clean" ]; then echo cleaned; exit 0; fi
i=1
for f in "$@"; do
  cp "tools/map_stmildreds_$f.luau" "Game/Config/_SMB$i.luau" || exit 1
  i=$((i+1))
done
sleep 1.5
echo "staged $# chunk(s)"
# Studio side (execute_luau, Edit) - runs the staged chunks in order:
#   local cfg = game.ReplicatedStorage.Config
#   local i = 1 while cfg:FindFirstChild("_SMB" .. i) do assert(loadstring(cfg["_SMB" .. i].Source))() i += 1 end
# Full rebuild: 00_lib 01_site 02_masonry 02b_windows_roofs 03_ground 04_tower 05_crypt 06_graveyard 07_corruption
# Checks (read-only): validate audit pathcheck   (_G.SMAUDIT_MODE = "doors"|"zfight"|"props"|"float"|"ramps"|"all")
# Afterwards: map_stmildreds_run.sh clean
