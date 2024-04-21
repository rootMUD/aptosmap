module supermap::map_manager {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::object::{Self, ConstructorRef, Object};
    use aptos_framework::timestamp;
    use aptos_std::string_utils::{Self};
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_token_objects::property_map;
    use std::option;
    use std::signer::address_of;
    use std::signer;
    use std::string::{Self, String};

    // coin
    use aptos_framework::coin::Coin;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    // vector
    use std::vector;

    /// Supermap error codes
    const ENOT_SIGNER_NOT_ADMIN: u64 = 1;
    const ENOT_VALID_MAP_TYPE: u64 = 2;
    const ENOT_MAP_OWNER: u64 = 3;
    const ENOT_VALID_BLOCK: u64 = 4;
    const ENOT_STACKABLE: u64 = 5;
    const ENOT_TYPEMATCH: u64 = 6;
    const ENOT_AMOUNT_MATCH: u64= 7;

    /// Supermap constants
    const STATE_SEED: vector<u8> = b"movecraft_signer";
    const MINT_SEED: vector<u8> = b"mint_signer";
    const BURN_SEED: vector<u8> = b"burn_signer";

    const MAP_COLLECTION_NAME: vector<u8> = b"Block";
    const MAP_COLLECTION_DESCRIPTION: vector<u8> = b"Movecraft Block";
    // TODO: update the block collection uri.
    const MAP_COLLECTION_URI: vector<u8> = b"block.svg";

    const LOG_MAP_TYPE: u64 = 11;
    const PLANK_MAP_TYPE: u64 = 12;

    const MAP_ID_KEY: vector<u8> = b"id";
    const MAP_TYPE_KEY: vector<u8> = b"type";
    const MAP_COUNT_KEY: vector<u8> = b"count";

    /// Global state
    struct State has key {
        // the signer cap of the module's resource account
        signer_cap: SignerCapability, 
        last_map_id: u64,
        // block address collection
        maps: SimpleMap<u64, address>,
        // events
        mint_map_events: event::EventHandle<MintMapEvents>
    }

    struct Map has key {
        // it should be a square.
        map_size: u64, 
        // use vector<u8> to represent the map
        map: vector<u8>,   
        property_mutator_ref: property_map::MutatorRef,        
    }

    // Movecraft events
    struct MintMapEvents has drop, store {
        name: String,
        description: String, 
        creator: address,
        event_timestamp: u64
    }

    // This function is only callable during publishing
    fun init_module(admin: &signer) {
        // Validate signer is admin
        assert!(signer::address_of(admin) == @supermap, ENOT_SIGNER_NOT_ADMIN);

        // Create the resource account with admin account and provided SEED constant
        let (resource_account, signer_cap) = account::create_resource_account(admin, STATE_SEED);

        move_to(&resource_account, State{
            signer_cap,
            last_map_id: 0,
            maps: simple_map::create(),
            mint_map_events: account::new_event_handle<MintMapEvents>(&resource_account)
        });

        // Create log and plank collection to the resource account
        collection::create_unlimited_collection(
            &resource_account,
            string::utf8(MAP_COLLECTION_DESCRIPTION),
            string::utf8(MAP_COLLECTION_NAME),
            option::none(),
            string::utf8(MAP_COLLECTION_URI),
        );
    }

    // see the hero guide: 
    // > https://mp.weixin.qq.com/s/P7VogEWxp-qGpIfaUPPARQ
    // mint a map
    public entry fun mint_map(owner: &signer, name: String, description: String, map: String, uri: String) {
        // TODO: mint a map here
        // * map is an nft
        // * set uri as the nft's uri.
        // * set size and map as the properties of the nft.
        // * also: there should be place to set 2d example uri of the map and 3d example uri of the map.
    }
    
    public entry fun update_map(owner: &signer, name: String, description: String, map: String, uri: String) {
        // TODO: update the map here
        // Only signer_cap owner could do this.
        // Will update line by line in the future.
    }

    #[view]
    public fun read_element(owner: &signer, map: Object<Map>, x: u64, y: u64): u8 {
        // TODO: return the elemnt of the map
        0
    }

    // TODO: check the map.
    // #[view]
    // public fun view_map_by_object(map_obj: Object<Map>): Map acquires Map {
}