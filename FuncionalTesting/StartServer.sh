#!/bin/bash

socat TCP-LISTEN:7777,fork /dev/ttyS4,raw,echo=0,b115200
