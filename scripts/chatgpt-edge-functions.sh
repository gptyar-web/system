#!/usr/bin/env bash
# Supabase CLI: audit (read-only) or explicitly confirmed deletion of known ChatGPT functions.
set -euo pipefail
[[ $# -eq 2 ]] || { echo 'Usage: bash scripts/chatgpt-edge-functions.sh audit|remove main|standby'; exit 2; }
mode=$1
case "$2" in
  main) project=efibfevyiepkwpnobaro ;;
  standby) project=pukanizbahswrupscfmg ;;
  *) echo 'Unknown project (expected main or standby)' >&2; exit 2 ;;
esac
[[ "$mode" == audit || "$mode" == remove ]] || { echo 'Expected audit or remove' >&2; exit 2; }
command -v supabase >/dev/null || { echo 'Install Supabase CLI and run supabase login locally' >&2; exit 1; }
echo "Project: $2 ($project)"
supabase functions list --project-ref "$project"
if [[ "$mode" == audit ]]; then
  echo 'READ ONLY: no changes made. Never share access tokens, secrets or user data.'
  exit 0
fi
echo 'This can break external clients. Verify a restorable backup, all dependencies and project ID.'
read -r -p "Type DELETE-CHATGPT-FUNCTIONS-$project to unlock deletion: " ok
[[ "$ok" == "DELETE-CHATGPT-FUNCTIONS-$project" ]] || { echo 'Cancelled'; exit 2; }
for fn in oauth-connector chatgpt-api chatgpt-mcp; do
  read -r -p "Delete $fn from $project? Type YES-$fn to confirm: " ok
  if [[ "$ok" == "YES-$fn" ]]; then
    supabase functions delete "$fn" --project-ref "$project"
  else
    echo "Skipped $fn"
  fi
done
supabase functions list --project-ref "$project"
echo 'Function deletion does not remove database grants, OAuth clients, Auth hooks or installed ChatGPT plugins.'
