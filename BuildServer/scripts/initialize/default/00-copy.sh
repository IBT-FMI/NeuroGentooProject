#!/bin/bash

on_error "rm --one-file-system -r '${ROOT%root}'"

cp --reflink -r roots/stemgentoo/root/ "${ROOT}"
