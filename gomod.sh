#!/usr/bin/env bash
set -euo pipefail

echo "Install Global Go Module"
go install golang.org/x/tools/cmd/godoc@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
