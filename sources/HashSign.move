module metaschool::hash_sign {
    use std::string::String;
    use std::vector;
    use aptos_framework::account;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::signer;

    struct Document has key, store {
        id: u64,
        content_hash: vector<u8>,
        creator: address,
        signers: vector<address>,
        signatures: vector<Signature>,
        is_completed: bool,
    }

    struct Signature has store, drop, copy {
        signer: address,
        timestamp: u64,
    }

    struct DocumentStore has key {
        documents: vector<Document>,
        document_counter: u64,
        create_document_events: event::EventHandle<CreateDocumentEvent>,
        sign_document_events: event::EventHandle<SignDocumentEvent>,
    }

    struct CreateDocumentEvent has drop, store {
        document_id: u64,
        creator: address,
    }

    struct SignDocumentEvent has drop, store {
        document_id: u64,
        signer: address,
    }

    // Initialize the DocumentStore for a new account
    public entry fun initialize(account: &signer) {
        let store = DocumentStore {
            documents: vector::empty(),
            document_counter: 0,
            create_document_events: account::new_event_handle<CreateDocumentEvent>(account),
            sign_document_events: account::new_event_handle<SignDocumentEvent>(account),
        };
        move_to(account, store);
    }

    // Create a new document
    public entry fun create_document(creator: &signer, content_hash: vector<u8>, signers: vector<address>) acquires DocumentStore {
        let creator_address = signer::address_of(creator);
        let store = borrow_global_mut<DocumentStore>(creator_address);
        
        let document = Document {
            id: store.document_counter,
            content_hash,
            creator: creator_address,
            signers,
            signatures: vector::empty(),
            is_completed: false,
        };

        vector::push_back(&mut store.documents, document);
        
        event::emit_event(&mut store.create_document_events, CreateDocumentEvent {
            document_id: store.document_counter,
            creator: creator_address,
        });

        store.document_counter = store.document_counter + 1;
    }

    // Sign a document
    public entry fun sign_document(signer: &signer, document_id: u64) acquires DocumentStore {
        let signer_address = signer::address_of(signer);
        let store = borrow_global_mut<DocumentStore>(signer_address);
        
        assert!(document_id < vector::length(&store.documents), 3); // Ensure document_id is within bounds

        let document = vector::borrow_mut(&mut store.documents, document_id);
        assert!(!document.is_completed, 1); // Document is not yet completed
        assert!(vector::contains(&document.signers, &signer_address), 2); // Signer is authorized

        let signature = Signature {
            signer: signer_address,
            timestamp: timestamp::now_microseconds(),
        };

        vector::push_back(&mut document.signatures, signature);

        event::emit_event(&mut store.sign_document_events, SignDocumentEvent {
            document_id,
            signer: signer_address,
        });

        // Check if all signers have signed
        if (vector::length(&document.signatures) == vector::length(&document.signers)) {
            document.is_completed = true;
        }
    }

    // Get document details
    public fun get_document(creator: address, document_id: u64): (vector<u8>, vector<address>, vector<Signature>, bool) acquires DocumentStore {
        let store = borrow_global<DocumentStore>(creator);
        assert!(document_id < vector::length(&store.documents), 3); // Ensure document_id is within bounds
        let document = vector::borrow(&store.documents, document_id);
        
        (document.content_hash, document.signers, document.signatures, document.is_completed)
    }
}