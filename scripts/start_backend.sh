#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ -x "$HOME/.dotnet/dotnet" ]; then
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$DOTNET_ROOT:$PATH"
fi
docker compose -f docker/docker-compose.yml up -d --wait
dotnet run --project backend/RentalApi
