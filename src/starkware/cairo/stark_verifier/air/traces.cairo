from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.stark_verifier.air.config import TracesConfig, traces_config_validate
from starkware.cairo.stark_verifier.air.layout import AirWithLayout
from starkware.cairo.stark_verifier.air.public_input import PublicInput
from starkware.cairo.stark_verifier.core.channel import (
    Channel,
    ChannelUnsentFelt,
    random_felts_to_prover,
)
from starkware.cairo.stark_verifier.core.table_commitment import (
    TableCommitment,
    TableCommitmentConfig,
    TableCommitmentWitness,
    TableDecommitment,
    TableUnsentCommitment,
    table_commit,
    table_decommit,
)

// A protocol component (see stark.cairo for details about protocol components) for the traces
// of the CPU AIR.
// This component is commonly right before the FRI component.
// In this case:
//   n_queries = n_fri_queries * 2^first_fri_step.
//   decommitment.original.n_queries = n_original_columns * n_queries.
//   decommitment.interaction.n_queries = n_interaction_columns * n_queries.

// Columns sizes.
const CONSTRAINT_DEGREE = 2;
const N_COMPOSITION_COLUMNS = CONSTRAINT_DEGREE;

// Commitment values for the Traces component. Used to generate a commitment by "reading" these
// values from the channel.
struct TracesUnsentCommitment {
    original: TableUnsentCommitment,
    interaction: TableUnsentCommitment,
}

// Commitment for the Traces component.
struct TracesCommitment {
    public_input: PublicInput*,
    // Commitment to the first trace.
    original: TableCommitment*,
    // The interaction elements that were sent to the prover after the first trace commitment (e.g.
    // memory interaction).
    interaction_elements: felt*,
    // Commitment to the second (interaction) trace.
    interaction: TableCommitment*,
}

// Responses for queries to the AIR commitment.
// The queries are usually generated by the next component down the line (e.g. FRI).
struct TracesDecommitment {
    // Responses for queries to the original trace.
    original: TableDecommitment*,
    // Responses for queries to the interaction trace.
    interaction: TableDecommitment*,
}

// A witness for a decommitment of the AIR traces over queries.
struct TracesWitness {
    original: TableCommitmentWitness*,
    interaction: TableCommitmentWitness*,
}

// Reads the traces commitment from the channel.
// Returns the commitment, along with GlobalValue required to evaluate the constraint polynomial.
func traces_commit{
    range_check_ptr, blake2s_ptr: felt*, bitwise_ptr: BitwiseBuiltin*, channel: Channel
}(
    air: AirWithLayout*,
    public_input: PublicInput*,
    unsent_commitment: TracesUnsentCommitment*,
    config: TracesConfig*,
) -> (commitment: TracesCommitment*) {
    alloc_locals;

    // Read original commitment.
    let (original_commitment) = table_commit(
        unsent_commitment=unsent_commitment.original, config=config.original
    );

    // Generate interaction elements for the first interaction.
    let (interaction_elements: felt*) = alloc();
    random_felts_to_prover(
        n_elements=air.layout.n_interaction_elements, elements=interaction_elements
    );

    // Read interaction commitment.
    let (interaction_commitment) = table_commit(
        unsent_commitment=unsent_commitment.interaction, config=config.interaction
    );

    return (
        commitment=new TracesCommitment(
            public_input=public_input,
            original=original_commitment,
            interaction_elements=interaction_elements,
            interaction=interaction_commitment,
        ),
    );
}

// Verifies a decommitment for the traces at the query indices.
// decommitment - holds the commited values of the leaves at the query_indices.
func traces_decommit{range_check_ptr, blake2s_ptr: felt*, bitwise_ptr: BitwiseBuiltin*}(
    air: AirWithLayout*,
    n_queries: felt,
    queries: felt*,
    commitment: TracesCommitment*,
    decommitment: TracesDecommitment*,
    witness: TracesWitness*,
) {
    table_decommit(
        commitment=commitment.original,
        n_queries=n_queries,
        queries=queries,
        decommitment=decommitment.original,
        witness=witness.original,
    );
    table_decommit(
        commitment=commitment.interaction,
        n_queries=n_queries,
        queries=queries,
        decommitment=decommitment.interaction,
        witness=witness.interaction,
    );
    return ();
}
