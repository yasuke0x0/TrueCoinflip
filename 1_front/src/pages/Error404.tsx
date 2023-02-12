import {Container, Nav, Navbar, Spinner} from "react-bootstrap";
import {useContext, useState} from "react";
import {WalletAuthContext} from "../context/walletAuthContext/WalletAuthContext";
import {WalletModel} from "../models";
import {toast} from "react-toastify";
import {Web3Context} from "../context/web3Context/Web3Context";

export default function Error404() {
    return <div className={"text-center"}>
        <h4>404 not found</h4>
    </div>
}