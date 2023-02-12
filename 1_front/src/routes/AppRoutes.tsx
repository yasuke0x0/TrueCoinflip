import React, {useContext} from 'react';

import {Routes, Route, BrowserRouter, Navigate} from 'react-router-dom'
import {WalletAuthContext} from "../context/walletAuthContext/WalletAuthContext";
import Login from "../pages/Login";
import Bets from "../pages/Bets";
import Error404 from "../pages/Error404";

function AppRoutes() {
    const {currentWallet} = useContext(WalletAuthContext);

    return <Routes>
        {currentWallet ? <>
                <Route path={'/'} element={<Bets/>}/>
            </> :
            <>
                <Route path={'/'} element={<Login/>}/>
            </>
        }
        <Route path={"*"} element={<Error404/>}/>
    </Routes>
}

export default AppRoutes;
