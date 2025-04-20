use action.{Action, Burn, Mint}
use aiken/collection/dict
use aiken/collection/list
use cardano/address
use cardano/assets.{PolicyId}
use cardano/transaction.{Input, NoDatum, Output, OutputReference, Transaction}

validator day_2(utxo_ref: OutputReference) {
  mint(redeemer: Action, policy_id: PolicyId, tx: Transaction) {
    trace @"Redeemer": redeemer

    let asset_qty_dict = assets.tokens(tx.mint, policy_id)

    when redeemer is {
      Mint ->
        // we can use pattern-matching instead of expect to reject gracefully
        when dict.to_pairs(asset_qty_dict) is {
          [Pair(_asset_name, qty)] -> and {
              qty == 1,
              list.any(
                tx.inputs,
                fn(input) { input.output_reference == utxo_ref },
              ),
            }
          _ -> False
        }

      Burn -> {
        expect [Pair(_asset_name, qty)] = dict.to_pairs(asset_qty_dict)

        qty == -1
      }
    }
  }

  else(_) {
    fail
  }
}

test day_2_test() {
  let nonce_utxo = OutputReference(#"0000", 0)
  let redeemer = Mint
  let tx =
    Transaction {
      ..transaction.placeholder,
      inputs: [
        Input {
          output_reference: nonce_utxo,
          output: Output {
            address: address.from_verification_key(#"abcd"),
            value: assets.zero,
            datum: NoDatum,
            reference_script: None,
          },
        },
      ],
      mint: assets.from_asset("PolicyId", "", 1),
    }

  day_2.mint(nonce_utxo, redeemer, "PolicyId", tx)
}
