import React, { useState, useEffect } from 'react';
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptosClient } from "@/utils/aptosClient";
import { InputTransactionData } from "@aptos-labs/wallet-adapter-react";
import axios from 'axios';
import { Modal, Button, Upload, message, Input, Spin } from 'antd';
import { useNavigate, useParams } from 'react-router-dom';

interface Signature {
  signer: string;
  timestamp: string;
}

interface Document {
  id: number;
  content_hash: string;
  creator: string;
  signers: string[];
  signatures: Signature[];
  is_completed: boolean;
}

const SigningPage: React.FC = () => {
  const { account, signAndSubmitTransaction } = useWallet();
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [document, setDocument] = useState<Document | null>(null);
  const [viewDocumentUrl, setViewDocumentUrl] = useState<string | null>(null);
  const [transactionInProgress, setTransactionInProgress] = useState(false);
  const [loading, setLoading] = useState(true);
  const moduleAddress = import.meta.env.VITE_APP_MODULE_ADDRESS;
  const moduleName = import.meta.env.VITE_APP_MODULE_NAME;

  useEffect(() => {
    if (id) {
      fetchDocument(Number(id));
    }
  }, [id]);

  const fetchDocument = async (docId: number) => {
    setLoading(true);
    try {
      const response = await aptosClient().view<[Document]>({
        payload: {
          function: `${moduleAddress}::${moduleName}::get_document`,
          typeArguments: [],
          functionArguments: [docId],
        },
      });

      if (response && response.length > 0) {
        const fetchedDocument = response[0];
        console.log("Fetched document:", fetchedDocument);
        setDocument(fetchedDocument);
        handleViewDocument(fetchedDocument.content_hash);
      } else {
        message.error('Document not found');
      }
    } catch (error) {
      console.error("Error fetching document:", error);
      message.error('Failed to fetch the document. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleViewDocument = async (cid: string) => {
    try {
      const url = `https://gateway.pinata.cloud/ipfs/${cid}`;
      const response = await axios.get(url, { responseType: 'blob' });
      const blob = new Blob([response.data], { type: response.headers['content-type'] });
      const objectUrl = URL.createObjectURL(blob);
      setViewDocumentUrl(objectUrl);
    } catch (error) {
      console.error("Error fetching document:", error);
      message.error("Failed to fetch the document. Please try again.");
    }
  };

  const handleSignDocument = async () => {
    if (!account || !document) return;
    setTransactionInProgress(true);
    try {
      const payload: InputTransactionData = {
        data: {
          function: `${moduleAddress}::${moduleName}::sign_document`,
          functionArguments: [document.id],
        }
      };
      await signAndSubmitTransaction(payload);
      message.success('Document signed successfully!');
      navigate('/'); // Redirect to the main page after signing
    } catch (error) {
      console.error("Error signing document:", error);
      message.error('Failed to sign the document. Please try again.');
    } finally {
      setTransactionInProgress(false);
    }
  };

  const canSign = () => {
    if (!account || !document) return false;
    return document.signers.includes(account.address) && 
           !document.signatures.some(sig => sig.signer === account.address) &&
           !document.is_completed;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <Spin size="large" />
      </div>
    );
  }

  if (!document) {
    return <div className="container mx-auto px-4 py-8">Document not found</div>;
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">Sign Document</h1>
      {viewDocumentUrl && (
        <div className="mb-8">
          <iframe
            src={viewDocumentUrl}
            style={{ width: '100%', height: '70vh', border: 'none' }}
            title="Document Viewer"
          />
        </div>
      )}
      <div className="mb-4">
        <p>Creator: {document.creator}</p>
        <p>Status: {document.is_completed ? 'Completed' : 'Pending'}</p>
        <p>Signatures: {document.signatures.length}/{document.signers.length}</p>
      </div>
      {canSign() ? (
        <Button onClick={handleSignDocument} type="primary" size="large" block loading={transactionInProgress}>
          Sign Document
        </Button>
      ) : (
        <Button type="primary" size="large" block disabled>
          {document.is_completed ? 'Document Completed' : 'Not Authorized to Sign'}
        </Button>
      )}
    </div>
  );
};

export default SigningPage;