import json
import os
from utils import parse_proof
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
    program = get_program_for_layout("starknet_with_keccak")

    with open("src/starkware/cairo/stark_verifier/air/example_proof.json", "r") as f:
        proof_json = json.load(f)

    result = parse_proof(identifiers=program.identifiers,
                         proof_json=proof_json)
    print(result)
