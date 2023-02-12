import {WalletModel} from "../../models";

const AUTH_LOCAL_STORAGE_KEY = 'auth-react-data'


const getAuthenticatedWalletFromLocalStorage = (): WalletModel | undefined => {
    if (!localStorage) {
        return
    }

    const lsValue: string | null = localStorage.getItem(AUTH_LOCAL_STORAGE_KEY)
    if (!lsValue) {
        return
    }

    try {
        const auth: WalletModel = JSON.parse(lsValue) as WalletModel
        if (auth) {
            // You can easily check auth_token expiration also
            return auth
        }
    } catch (error) {
        console.error('AUTH LOCAL STORAGE PARSE ERROR', error)
    }
}

const setAuthenticatedWalletInLocalStorage = (auth: WalletModel | undefined) => {
    if (!localStorage) {
        return
    }
    try {
        const lsValue = JSON.stringify(auth)
        localStorage.setItem(AUTH_LOCAL_STORAGE_KEY, lsValue)
    } catch (error) {
        console.error('AUTH LOCAL STORAGE SAVE ERROR', error)
    }
}

const removeAuthenticatedWalletFromLocalStorage = () => {
    if (!localStorage) {
        return
    }

    try {
        localStorage.removeItem(AUTH_LOCAL_STORAGE_KEY)
    } catch (error) {
        console.error('AUTH LOCAL STORAGE REMOVE ERROR', error)
    }
}

export {getAuthenticatedWalletFromLocalStorage, setAuthenticatedWalletInLocalStorage, removeAuthenticatedWalletFromLocalStorage, AUTH_LOCAL_STORAGE_KEY}

