import {createContext, Dispatch, SetStateAction, useReducer, useState} from "react";
import {WalletModel} from "../../models";
import Web3 from "web3";

type Web3ContextProps = {
    instance: Web3
    setInstance: Dispatch<SetStateAction<Web3>>
}

const web3ContextPropsState = {
    instance: new Web3(Web3.givenProvider),
    setInstance: () => {
    }
}

export const Web3Context = createContext<Web3ContextProps>(web3ContextPropsState)


const Web3ContextProvider = ({children}: { children: JSX.Element }) => {
    const [web3, setWeb3] = useState(web3ContextPropsState.instance);

    return (
        <Web3Context.Provider value={{instance: web3, setInstance: setWeb3}}>
            {children}
        </Web3Context.Provider>
    )
}

export {Web3ContextProvider}
