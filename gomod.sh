#!/usr/bin/env bash

echo "Install Global Go Module"
go get -U golang.org/x/tools/cmd/godoc
go get -U github.com/golang/lint/golint
go get -u honnef.co/go/tools/cmd/staticcheck
