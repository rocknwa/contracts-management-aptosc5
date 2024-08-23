import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { CardHeader, CardTitle } from "@/components/ui/card";
import { WalletSelector } from "./components/WalletSelector";
import ContractManagement from "@/components/ContractManagement";
import SigningDocument from "@/components/SigningDocument";

function App() {
  const { connected } = useWallet();

  return (
    <div className="min-h-screen flex flex-col">      
      <main className="flex-grow">
        {connected ? (
          <Router>
            <Routes>
              <Route path="/" element={<ContractManagement />} />
              <Route path="/sign/:id" element={<SigningDocument />} />
            </Routes>
          </Router>
        ) : (
          <div className="flex items-center justify-center h-full">
            <CardHeader>
              <CardTitle>To get started Connect a wallet</CardTitle>
              <WalletSelector />
            </CardHeader>
          </div>
        )}
      </main>
    </div>
  );
}

export default App;