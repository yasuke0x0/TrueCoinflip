import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

import 'bootstrap/dist/css/bootstrap.min.css';
import 'react-toastify/dist/ReactToastify.css';

import {QueryClient, QueryClientProvider} from "react-query";
import {WalletAuthContextProvider} from "./context/walletAuthContext/WalletAuthContext";
import {Web3ContextProvider} from "./context/web3Context/Web3Context";
import {BrowserRouter} from "react-router-dom";
import {ToastContainer} from "react-toastify";


const queryClient = new QueryClient()
const root = ReactDOM.createRoot(
    document.getElementById('root') as HTMLElement
);


root.render(
    <React.StrictMode>
        <ToastContainer/>

        <QueryClientProvider client={queryClient}>
            <WalletAuthContextProvider>
                <Web3ContextProvider>
                    <BrowserRouter>
                        <App/>
                    </BrowserRouter>
                </Web3ContextProvider>
            </WalletAuthContextProvider>
        </QueryClientProvider>
    </React.StrictMode>
);
