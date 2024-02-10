#!/usr/bin/env bash

source .venv/bin/activate
python src/main.py -l starknet_with_keccak < resources/main_proof.json > resources/main_parsed_proof.txt
deactivate
