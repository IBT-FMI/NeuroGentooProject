#!/bin/bash

on_error "rm -r '${ROOT%root}"

cp -r roots/stemgentoo/root/ "${ROOT}"
