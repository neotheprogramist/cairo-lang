import argparse
import json
import os
import sys
from utils import parse_proof, SUPPORTED_LAYOUTS
from starkware.cairo.lang.cairo_constants import DEFAULT_PRIME
from starkware.cairo.lang.compiler.cairo_compile import compile_cairo_files
from starkware.cairo.lang.compiler.program import Program
from starkware.cairo.lang.compiler.scoped_name import ScopedName


def get_program_for_layout(layout: str) -> Program:
    return compile_cairo_files(
        [os.path.join("src/starkware/cairo/stark_verifier/air",
                      f"layouts/{layout}/verify.cairo")],
        prime=DEFAULT_PRIME,
        debug_info=True,
        main_scope=ScopedName.from_string(
            f"starkware.cairo.stark_verifier.air.layouts.{layout}.verify"
        ),
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Process layout parameter.",
        usage="main.py -l <layout> < path/to/proof.json"
    )
    parser.add_argument(
        "-l", "--layout",
        type=str,
        choices=SUPPORTED_LAYOUTS,
        help="Layout to be run with",
        required=True,
    )

    args = parser.parse_args()

    program_input = sys.stdin.read()
    program = get_program_for_layout(args.layout)

    proof_json = json.loads(program_input)
    if proof_json["public_input"]["layout"] == "recursive_large_output":
        proof_json["public_input"]["layout"] == "recursive"

    result = parse_proof(identifiers=program.identifiers,
                         proof_json=proof_json)
    print(result)
