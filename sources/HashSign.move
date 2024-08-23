module HashSign::hash_sign_01 {
    // Import the necessary libraries/modules
    use std::string::String;  // String handling library
    use std::vector;          // Vector (dynamic array) library
    use aptos_framework::account;  // Account management module from the Aptos framework
    use aptos_framework::event;    // Event handling module from the Aptos framework
    use aptos_framework::timestamp; // Timestamp management module from the Aptos framework
    use aptos_framework::signer;   // Signer management module from the Aptos framework

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

    // Define the structure to store all documents and related events
    struct DocumentStore has key {
        documents: vector<Document>,  // List of all documents created
        document_counter: u64,        // Counter to assign unique IDs to documents
        // Event handle for document creation events
        create_document_events: event::EventHandle<CreateDocumentEvent>,  
        // Event handle for document signing events
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

    // Initialize the DocumentStore for a new account
    public entry fun initialize(account: &signer) {
        // Create a new DocumentStore object and initialize its fields
        let store = DocumentStore {
            // Initialize an empty vector for documents
            documents: vector::empty(),  // ASSIGNMENT #1
            // Initialize the document counter to 0 
            document_counter: 0,  // ASSIGNMENT #2
            // Create an event handle for document creation events
            create_document_events: account::new_event_handle<CreateDocumentEvent>(account),  
            // Create an event handle for document signing events
            sign_document_events: account::new_event_handle<SignDocumentEvent>(account),  // ASSIGNMENT #3
        };
        // Move the created DocumentStore to the specified account
        move_to(account, store);  // ASSIGNMENT #4
    }

    // Create a new document
    public entry fun create_document(creator: &signer, content_hash: vector<u8>, signers: vector<address>) acquires DocumentStore {
        // Get the creator's address
        let creator_address = signer::address_of(creator); // ASSIGNMENT #5
        // Borrow a mutable reference to the DocumentStore associated with the creator's address
        let store = borrow_global_mut<DocumentStore>(creator_address); // ASSIGNMENT #6
        
        // Create a new Document object and initialize its fields
        let document = Document {
            // Assign a unique ID based on the document counter
            id: store.document_counter,  
            // Store the provided content hash
            content_hash,
            // Store the creator's address  
            creator: creator_address, // ASSIGNMENT #7
            // Store the provided list of signers 
            signers,  
            // Initialize an empty vector for signatures
            signatures: vector::empty(), // ASSIGNMENT #8
            // Set the document to false as not completed initially 
            is_completed: false,  // ASSIGNMENT #9
        };

        // Add the new document to the store's documents vector
        vector::push_back(&mut store.documents, document);
        
        // Emit an event to signal the creation of a new document
        event::emit_event(&mut store.create_document_events, CreateDocumentEvent {
            document_id: store.document_counter,  // Use the current document counter as the document ID
            creator: creator_address,  // Store the creator's address in the event
        });

        // Increment the document counter for the next document creation
        store.document_counter = store.document_counter + 1; // ASSIGNMENT #10
    }

    // Sign a document
    public entry fun sign_document(signer: &signer, document_id: u64) acquires DocumentStore {
        // Get the signer's address
        let signer_address = signer::address_of(signer); // ASSIGNMENT #11
        // Borrow a mutable reference to the DocumentStore associated with the signer's address
        let store = borrow_global_mut<DocumentStore>(signer_address); // ASSIGNMENT #12
        
        // Ensure the document_id is within bounds
        assert!(document_id < vector::length(&store.documents), 3); // ASSIGNMENT #13

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
            document.is_completed = true; // ASSIGNMENT #14
        }
    }

    // Get document details
    public fun get_document(creator: address, document_id: u64): (String, vector<address>, vector<Signature>, bool) acquires DocumentStore {
        // Borrow a reference to the DocumentStore associated with the creator's address
        let store = borrow_global<DocumentStore>(creator); // ASSIGNMENT #15
        // Ensure the document_id is within bounds
        assert!(document_id < vector::length(&store.documents), 3); // ASSIGNMENT #16
        // Borrow a reference to the document with the specified ID
        let document = vector::borrow(&store.documents, document_id); // ASSIGNMENT #17
        
        // Return the document's content hash, signers, signatures, and completion status
        (document.content_hash, document.signers, document.signatures, document.is_completed)
    }
}
