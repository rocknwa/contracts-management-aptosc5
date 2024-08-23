module HashSign::hash_sign_01 {
    // Import the necessary libraries/modules
    use std::string::String;  // String handling library
    use std::vector;          // Vector (dynamic array) library
    use aptos_framework::account;  // Account management module from the Aptos framework
    use aptos_framework::event;    // Event handling module from the Aptos framework
    use aptos_framework::timestamp; // Timestamp management module from the Aptos framework
    use aptos_std::simple_map::{Self, SimpleMap};

    // Define the structure to store document details
    struct Document has key, store {
        id: u64,                        // Unique identifier for the document
        content_hash: vector<u8>,       // Hash of the document content
        creator: address,               // Address of the document creator
        signers: vector<address>,       // List of addresses who are signers of the document
        signatures: vector<Signature>,  // List of signatures added to the document
        is_completed: bool,             // Boolean indicating if all signers have signed the document
    }

    // Define the structure to store a signature
    struct Signature has store, drop, copy {
        signer: address,   // Address of the signer
        timestamp: u64,    // Timestamp when the document was signed
    }

    struct GlobalDocumentStore has key {
        documents: SimpleMap<u64, Document>,
        document_counter: u64,
    }

    struct EventStore has key {
        create_document_events: event::EventHandle<CreateDocumentEvent>,
        sign_document_events: event::EventHandle<SignDocumentEvent>,
    }

    // Define the event structure for document creation
    struct CreateDocumentEvent has drop, store {
        document_id: u64,   // Unique ID of the created document
        creator: address,   // Address of the document creator
    }

    // Define the event structure for document signing
    struct SignDocumentEvent has drop, store {
        document_id: u64,  // Unique ID of the signed document
        signer: address,   // Address of the signer
    }

    // Initialize the GlobalDocumentStore and EventStore
    fun init_module(account: &signer) {
        move_to(account, GlobalDocumentStore {
            documents: simple_map::create(),
            document_counter: 0,
        });
        move_to(account, EventStore {
            create_document_events: account::new_event_handle<CreateDocumentEvent>(account),
            sign_document_events: account::new_event_handle<SignDocumentEvent>(account),
        });
    }

    // Create a new document
    public entry fun create_document(creator: &signer, content_hash: String, signers: vector<address>) acquires GlobalDocumentStore, EventStore {
        // Get the creator's address
        let creator_address = std::signer::::YOUR_CODE_GOES_HERE(creator); // ASSIGNMENT #5
        // Borrow a mutable reference to the DocumentStore associated with the creator's address
        let store = YOUR_CODE_GOES_HERE<DocumentStore>(@HashSign); // ASSIGNMENT #6
        let event_store = borrow_global_mut<EventStore>(@HashSign);
        
        // Create a new Document object and initialize its fields
        let document = Document {
            // Assign a unique ID based on the document counter
            id: store.document_counter,  
            // Store the provided content hash
            content_hash,
            // Store the creator's address  
            creator: YOUR_CODE_GOES_HERE, // ASSIGNMENT #7
            // Store the provided list of signers 
            signers,  
            // Initialize an empty vector for signatures
            signatures: vector::YOUR_CODE_GOES_HERE(), // ASSIGNMENT #8
            // Set the document to false as not completed initially 
            is_completed: YOUR_CODE_GOES_HERE,  // ASSIGNMENT #9
        };

        simple_map::add(&mut store.documents, store.document_counter, document);
        
        // Emit an event to signal the creation of a new document
        event::emit_event(&mut event_store.create_document_events, CreateDocumentEvent {
            document_id: store.document_counter,  // Use the current document counter as the document ID
            creator: creator_address,  // Store the creator's address in the event
        });

        // Increment the document counter for the next document creation
        store.document_counter = YOUR_CODE_GOES_HERE; // ASSIGNMENT #10
    }

    // Sign a document
    public entry fun sign_document(signer: &signer, document_id: u64) acquires GlobalDocumentStore, EventStore {
        // Get the signer's address
        let signer_address = YOUR_CODE_GOES_HERE; // ASSIGNMENT #11
        // Borrow a mutable reference to the DocumentStore associated with the signer's address
        let store = YOUR_CODE_GOES_HERE<DocumentStore>(signer_address); // ASSIGNMENT #12
        
        // Ensure the document_id is within bounds
        assert!(YOUR_CODE_GOES_HERE < vector::length(&store.documents), 3); // ASSIGNMENT #13

        // Borrow a mutable reference to the document with the specified ID
        let document = vector::borrow_mut(&mut store.documents, document_id);
        // Ensure the document is not yet completed
        assert!(!document.is_completed, 1);
        // Ensure the signer is authorized to sign the document
        assert!(vector::contains(&document.signers, &signer_address), 2);

        // Create a new Signature object and initialize its fields
        let signature = Signature {
            signer: signer_address,  // Store the signer's address
            timestamp: timestamp::now_microseconds(),  // Store the current timestamp in microseconds
        };

        // Add the new signature to the document's signatures vector
        vector::push_back(&mut document.signatures, signature);

        // Emit an event to signal the signing of the document
        event::emit_event(&mut store.sign_document_events, SignDocumentEvent {
            document_id,  // Store the document ID in the event
            signer: signer_address,  // Store the signer's address in the event
        });

        // Check if all signers have signed the document
        if (vector::length(&document.signatures) == vector::length(&document.signers)) {
            // If all signers have signed, mark the document as true and completed
            document.is_completed = YOUR_CODE_GOES_HERE; // ASSIGNMENT #14
        }
    }

    // Get document details
    #[view]
    public fun get_document(document_id: u64): Document acquires GlobalDocumentStore {
        let store = borrow_global<GlobalDocumentStore>(@HashSign);
        assert!(simple_map::contains_key(&store.documents, &document_id), 4); // Ensure document exists
        *simple_map::borrow(&store.documents, &document_id)
    }

    // Get all documents
    #[view]
    public fun get_all_documents(): vector<Document> acquires GlobalDocumentStore {
        let store = borrow_global<GlobalDocumentStore>(@HashSign);
        let all_documents = vector::empty<Document>();
        let i = 0;
        while (i < store.document_counter) {
            if (simple_map::contains_key(&store.documents, &i)) {
                vector::push_back(&mut all_documents, *simple_map::borrow(&store.documents, &i));
            };
            i = i + 1;
        };
        all_documents
    }

    // Get total number of documents
    #[view]
    public fun get_total_documents(): u64 acquires GlobalDocumentStore {
        let store = borrow_global<GlobalDocumentStore>(@HashSign);
        store.document_counter
    }
}
