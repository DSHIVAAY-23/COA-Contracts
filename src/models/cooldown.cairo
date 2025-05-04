use starknet::ContractAddress;
use dojo::model;

#[derive(Copy, Drop, Serde, IntrospectPacked, Debug)]
#[dojo::model]
pub struct Cooldown {
    #[key]
    pub player_id: ContractAddress,
    #[key]
    pub action_type: felt252,
    pub ready_at: u64,
}


use starknet::{ContractAddress, get_block_timestamp};
use dojo::world::IWorldDispatcher;
use super::models::cooldown::Cooldown;

#[dojo::interface]
trait ICooldown<TContractState> {
    fn set_cooldown(ref self: TContractState, player_id: ContractAddress, action_type: felt252, delay: u64);
}

#[dojo::contract]
mod cooldown {
    use super::ICooldown;
    use starknet::get_block_timestamp;
    use dojo::world::IWorldDispatcher;

    #[abi(embed_v0)]
    impl CooldownImpl of super::ICooldown<ContractState> {
        fn set_cooldown(ref self: ContractState, player_id: ContractAddress, action_type: felt252, delay: u64) {
            let mut world = self.world(@"coa_contracts"); // Replace with actual world name
            let current_time = get_block_timestamp();
            let ready_at = current_time + delay;
            let cooldown = Cooldown {
                player_id,
                action_type,
                ready_at,
            };
            world.write_model(cooldown);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::models::cooldown::Cooldown;
    use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
    use dojo::world::TestWorld;
    use dojo::test_utils::spawn_test_world;

    #[test]
    fn test_cooldown_model_initialization() {
        let player_id = contract_address_const::<0x123>();
        let action_type = 'attack';
        let ready_at = 1000000; // Example timestamp

        let cooldown = Cooldown {
            player_id,
            action_type,
            ready_at,
        };

        assert(cooldown.player_id == player_id, 'Player ID mismatch');
        assert(cooldown.action_type == action_type, 'Action type mismatch');
        assert(cooldown.ready_at == ready_at, 'Ready at mismatch');
    }

    #[test]
    fn test_set_cooldown() {
        let (world, _) = spawn_test_world();
        let player_id = contract_address_const::<0x123>();
        let action_type = 'attack';
        let delay = 100; // 100 seconds

        let current_time = get_block_timestamp();
        let ready_at = current_time + delay;
        let cooldown = Cooldown {
            player_id,
            action_type,
            ready_at,
        };
        world.write_model(cooldown);

        let stored_cooldown = world.read_model::<Cooldown>((player_id, action_type));
        assert(stored_cooldown.ready_at == ready_at, 'Incorrect ready_at');
    }
}
