import {createContext, Dispatch, SetStateAction, useReducer, useState} from "react";
import {setAuthenticatedWalletInLocalStorage} from "./WalletcontextHelper";
import {WalletModel} from "../../models";
import * as authHelper from './WalletcontextHelper'
import {toast} from "react-toastify";

type WalletAuthContextProps = {
    currentWallet: WalletModel | undefined
    setCurrentWallet: Dispatch<SetStateAction<WalletModel | undefined>>
    saveAuthenticatedWalletInLocalStorage: (auth: WalletModel | undefined) => void
    logout: () => void
}

const walletAuthContextPropsState = {
    currentWallet: undefined,
    setCurrentWallet: () => {
    },
    saveAuthenticatedWalletInLocalStorage: () => {
    },
    logout: () => {
    }
}

export const WalletAuthContext = createContext<WalletAuthContextProps>(walletAuthContextPropsState)


const WalletAuthContextProvider = ({children}: { children: JSX.Element }) => {
    const [currentWallet, setCurrentWallet] = useState<WalletModel | undefined>(authHelper.getAuthenticatedWalletFromLocalStorage())
    const saveAuthenticatedWalletInLocalStorage = (wallet: WalletModel | undefined) => {
        setAuthenticatedWalletInLocalStorage(wallet)
        if (wallet) {
            authHelper.setAuthenticatedWalletInLocalStorage(wallet)
        } else {
            authHelper.removeAuthenticatedWalletFromLocalStorage()
        }
    }

    const logout = () => {
        saveAuthenticatedWalletInLocalStorage(undefined)
        setCurrentWallet(undefined)
        toast.info("You are disconnected")
    }

    return (
        <WalletAuthContext.Provider value={{
            currentWallet,
            setCurrentWallet,
            saveAuthenticatedWalletInLocalStorage,
            logout
        }}>
            {children}
        </WalletAuthContext.Provider>
    )
}

export {WalletAuthContextProvider}
