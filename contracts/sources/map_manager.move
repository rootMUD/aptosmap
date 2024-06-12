module supermap::map_manager {
    use aptos_framework::account::{Self, SignerCapability};
    use aptos_framework::event;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_token_objects::property_map;
    use std::option;
    use std::signer;
    use std::string::{Self, String};

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
        // use vector<u64> to represent the map
        map: vector<vector<u64>>,   
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
    public entry fun mint_map(owner: &signer, name: String, description: String, uri: String, map_size: u64, map: vector<vector<u64>>) acquires State {
        // TODO: mint a map here
        // * map is an nft
        // * set uri as the nft's uri.
        // * set size and map as the properties of the nft.
        // * also: there should be place to set 2d example uri of the map and 3d example uri of the map.

        // generate resource acct
        let state = borrow_global_mut<State>(get_resource_account_address());
        let map_id = state.last_map_id + 1;
        let resource_account = account::create_signer_with_capability(&state.signer_cap);

        let constructor_ref = token::create_named_token(
            &resource_account,
            string::utf8(MAP_COLLECTION_NAME),
            description,
            name,
            option::none(),
            uri,
        );
        let token_signer = object::generate_signer(&constructor_ref);

        // <-- create properties
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref); 
        let properties = property_map::prepare_input(vector[], vector[], vector[]);

        property_map::init(&constructor_ref, properties);

        property_map::add_typed<u64>(
            &property_mutator_ref,
            string::utf8(b"size"),
            map_size,
        );
        // create properties -->

        let map_obj = Map {
            map_size,
            map,
            property_mutator_ref,
        };
        move_to(&token_signer, map_obj);

        // move to creator
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let creator_address = signer::address_of(owner);
        object::transfer_with_ref(object::generate_linear_transfer_ref(&transfer_ref), creator_address);

        // Update global state
        let map_address = signer::address_of(&token_signer);
        simple_map::add(&mut state.maps, map_id, map_address);

        state.last_map_id = map_id;

        // Emit a new mintEvent
        let event = MintMapEvents {
            name,
            description, 
            creator: creator_address,
            event_timestamp: timestamp::now_seconds()   
        };
        event::emit_event(&mut state.mint_map_events, event);
    }
    
    public entry fun update_map(owner: &signer, name: String, map_size: u64, map: vector<vector<u64>>) acquires Map {
        // TODO: update the map here
        // Only signer_cap owner could do this.
        // Will update line by line in the future.

        // generate resource acct
        let resource_account_addr = get_resource_account_address();

        // get map obj
        let map_address = token::create_token_address(
            &resource_account_addr,
            &string::utf8(MAP_COLLECTION_NAME),
            &name,
        );
        let map_obj = object::address_to_object<Map>(map_address);

        // validate owner
        let creator_address = signer::address_of(owner);
        assert!(object::is_owner(map_obj, creator_address), ENOT_MAP_OWNER);

        // update map property
        let map_struct = borrow_global_mut<Map>(map_address);
        property_map::update_typed(
            &map_struct.property_mutator_ref,
            &string::utf8(b"size"),
            map_size,
        );

        // update map object
        map_struct.map_size = map_size;
        map_struct.map = map;
    }

    #[view]
    public fun read_element(map_obj: Object<Map>, x: u64, y: u64): u64 acquires Map {
        // TODO: return the elemnt of the map
        let map_address = object::object_address(&map_obj);
        let map_struct = borrow_global<Map>(map_address);
        let arr = *vector::borrow<vector<u64>>(&map_struct.map, x);
        *vector::borrow<u64>(&arr, y)
    }

    #[view]
    public fun view_map_by_object(map_obj: Object<Map>): Map acquires Map {
        let map_address = object::object_address(&map_obj);
        move_from<Map>(map_address)
    }

    #[view]
    public fun view_map_by_id(map_id: u64): Map acquires State, Map {
        let state = borrow_global<State>(get_resource_account_address());
        let map_address = *simple_map::borrow(&state.maps, &map_id);
        move_from<Map>(map_address)
    }

    inline fun get_resource_account_address(): address {
        account::create_resource_address(&@supermap, STATE_SEED)
    }
}