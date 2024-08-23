import React, { useState, useEffect } from 'react';
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptosClient } from "@/utils/aptosClient";
import { InputTransactionData } from "@aptos-labs/wallet-adapter-react";
import axios from 'axios';
import { Modal, Button, Upload, message, Input, Tabs } from 'antd';
import { UploadOutlined, PlusOutlined, FileTextOutlined, ShareAltOutlined } from '@ant-design/icons';
import { WalletSelector } from "./WalletSelector";
import { useNavigate, useParams } from 'react-router-dom';

const { TabPane } = Tabs;

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

interface DocumentStore {
  documents: Document[];
  document_counter: number;
}

export const ContractManagement: React.FC = () => {
    const { account, signAndSubmitTransaction } = useWallet();
    const [isRegistered, setIsRegistered] = useState(false);
    const [documents, setDocuments] = useState<Document[]>([]);
    const [pendingDocuments, setPendingDocuments] = useState<Document[]>([]);
    const [isModalVisible, setIsModalVisible] = useState(false);
    const [file, setFile] = useState<File | null>(null);
    const [signers, setSigners] = useState("");
    const [transactionInProgress, setTransactionInProgress] = useState(false);
    const [viewDocumentUrl, setViewDocumentUrl] = useState<string | null>(null);
    const moduleAddress = process.env.VITE_APP_MODULE_ADDRESS;
    const moduleName = process.env.VITE_APP_MODULE_NAME
    const navigate = useNavigate();

useEffect(() => {
    if (account) {
      fetchDocuments();
      fetchPendingDocuments();
    }
  }, [account]);

  const fetchDocuments = async () => {
    if (!account) return;
    try {
        const response = await aptosClient().view<[Document]>({
            payload: {
                function: `${moduleAddress}::${moduleName}::get_all_documents`,
                typeArguments: [],
                functionArguments: [],
            }
          });
          if (Array.isArray(response) && response.length > 0) {
            console.log("All documents:", response[0]);
            const userDocuments = response[0].filter(
              doc => doc.creator === account.address
            );
            console.log("User documents:", userDocuments);
            setDocuments(userDocuments);
          } else {
            console.log("No documents found or unexpected response format");
            setDocuments([]);
          }
    } catch (error) {
      console.error("Error fetching documents:", error);
    }
  };

  const fetchPendingDocuments = async () => {
    if (!account) return;
    try {
      const response = await aptosClient().view<Document[]>({
        payload: {
          function: `${moduleAddress}::${moduleName}::get_all_documents`,
          typeArguments: [],
          functionArguments: [],
        }
      });

      if (Array.isArray(response) && response.length > 0) {
        console.log("All documents:", response[0]);
        const pendingDocs = response[0].filter(doc => 
          doc.signers.includes(account.address) && 
          !doc.signatures.some(sig => sig.signer === account.address) &&
          !doc.is_completed
        );
        console.log("Pending documents:", pendingDocs);
        setPendingDocuments(pendingDocs);
      } else {
        console.log("No pending documents found or unexpected response format");
        setPendingDocuments([]);
      }
    } catch (error) {
      console.error("Error fetching pending documents:", error);
      message.error("Failed to fetch pending documents. Please try again.");
    }
  };

  const uploadToPinata = async (file: File) => {
    const url = `https://api.pinata.cloud/pinning/pinFileToIPFS`;

    // Create form data
    let formData = new FormData();
    formData.append('file', file);
    const metadata = JSON.stringify({
        name: 'Property Image',
    });
    formData.append('pinataMetadata', metadata);
    const options = JSON.stringify({
        cidVersion: 0,
    })
    formData.append('pinataOptions', options);

    try {
        const res = await axios.post(url, formData, {
            method: "post",
            data: formData,
            headers: {
                'pinata_api_key': process.env.VITE_APP_PINATA_API_KEY,
                'pinata_secret_api_key': process.env.VITE_APP_PINATA_SECRET_API_KEY,
                "Content-Type": "multipart/form-data"
            },
            });
      return res.data.IpfsHash;
    } catch (error) {
      console.error("Error uploading to Pinata:", error);
      throw error;
    }
  };

  const handleCreateDocument = async () => {
    if (!account || !file || !signers) return;
    setTransactionInProgress(true);
    try {
      const cid = await uploadToPinata(file);
      const signerAddresses = signers.split(',').map(addr => addr.trim());
      const payload: InputTransactionData = {
        data: {
          function: `${moduleAddress}::${moduleName}::create_document`,
          functionArguments: [cid, signerAddresses],
        }
      };
      await signAndSubmitTransaction(payload);
      setIsModalVisible(false);
      setFile(null);
      setSigners("");
      fetchDocuments();
    } catch (error) {
      console.error("Error creating document:", error);
    } finally {
      setTransactionInProgress(false);
    }
  };

  const handleShare = (docId: number) => {
    const signingLink = `${window.location.origin}/sign/${docId}`;
    navigator.clipboard.writeText(signingLink).then(() => {
      message.success('Signing link copied to clipboard!');
    }, (err) => {
      console.error('Could not copy text: ', err);
    });
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
  const renderDocumentCard = (doc: Document, isPending: boolean) => (
    <div key={doc.id} className="bg-white shadow-md rounded-lg p-6">
      <p className="mb-2">Status: {doc.is_completed ? 'Completed' : 'Pending'}</p>
      <p className="mb-4">Signatures: {doc.signatures.length}/{doc.signers.length}</p>
      <div className="flex space-x-2">
        <Button onClick={() => handleViewDocument(doc.content_hash)} type="primary" block>
          View Document
        </Button>
        {isPending ? (
          <Button type="primary" onClick={() => navigate(`/sign/${doc.id}`)} block>
            Sign Document
          </Button>
        ) : (
          <Button onClick={() => handleShare(doc.id)} icon={<ShareAltOutlined />} block>
            Share
          </Button>
        )}
      </div>
    </div>
  );

  return (
        <div className="container mx-auto px-4 py-8">
          <div className="flex justify-between items-center mb-8">
            <h1 className="text-3xl font-bold">HashSign Dashboard</h1>
            <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
              <Button
                onClick={() => setIsModalVisible(true)}
                type="primary"
                icon={<PlusOutlined />}
                size="large"
              >
                Create Document
              </Button>
              <WalletSelector />
            </div>
          </div>
    
          <Tabs defaultActiveKey="1">
            <TabPane tab="Your Documents" key="1">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {documents.map(doc => renderDocumentCard(doc, false))}
              </div>
            </TabPane>
            <TabPane tab="Pending Signatures" key="2">
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {pendingDocuments.map(doc => renderDocumentCard(doc, true))}
              </div>
            </TabPane>
          </Tabs>

      <Modal
        title="Create New Document"
        open={isModalVisible}
        onOk={handleCreateDocument}
        onCancel={() => setIsModalVisible(false)}
        confirmLoading={transactionInProgress}
      >
        <Upload
          beforeUpload={(file) => {
            const isLt25M = file.size / 1024 / 1024 < 25;
            if (!isLt25M) {
              message.error('File must be smaller than 25MB!');
            } else {
              setFile(file);
            }
            return false;
          }}
        >
          <Button icon={<UploadOutlined />}>Select File (Max: 25MB)</Button>
        </Upload>
        <Input
          placeholder="Enter signer addresses (comma-separated)"
          value={signers}
          onChange={(e) => setSigners(e.target.value)}
          className="mt-4"
        />
      </Modal>

      <Modal
        title="View Document"
        open={!!viewDocumentUrl}
        onCancel={() => setViewDocumentUrl(null)}
        footer={null}
        width={800}
      >
        {viewDocumentUrl && (
          <iframe
            src={viewDocumentUrl}
            style={{ width: '100%', height: '70vh', border: 'none' }}
            title="Document Viewer"
          />
        )}
      </Modal>
    </div>
  );
};

export default ContractManagement;
