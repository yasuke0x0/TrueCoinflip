import {useContext, useEffect, useState} from "react";
import Web3 from 'web3';
import {toast} from "react-toastify";
import contractABI from '../coinfFlipABI.json'
import {CONTRACT_ADRESS} from "../constants";
import {AbiItem} from "web3-utils";
import {Contract} from "web3-eth-contract";
import {Spinner} from "react-bootstrap";
import {BetModel, WalletModel} from "../models";
import {WalletAuthContext} from "../context/walletAuthContext/WalletAuthContext";
import {Web3Context} from "../context/web3Context/Web3Context";

const currentDate = new Date()
const web3 = new Web3(Web3.givenProvider)

export default function Login() {
    // const {error, data, isLoading} = useQuery("dogs", () => axios.get<{fileSizeBytes: number, url: string}>("https://random.dog/woof.json"))
    const walletAuthContext = useContext(WalletAuthContext);

    const [isConnectingWallet, setIsConnectingWallet] = useState<boolean>(false)

    // Handles wallet connexion before start playing
    const handleConnectWallet = async () => {
        setIsConnectingWallet(true)
        // Request wallet connexion & get checked account(s)
        try {
            const accounts = await web3.eth.requestAccounts()

            if (accounts.length > 0) {
                // Get checked account & balance
                const account = accounts[0]
                const balance = await web3.eth.getBalance(account)
                const walletData: WalletModel = {
                    address: account,
                    balance: Number(web3.utils.fromWei(balance))
                }

                walletAuthContext.setCurrentWallet(walletData)
                walletAuthContext.saveAuthenticatedWalletInLocalStorage(walletData)
            } else {
                toast.error("You need to select at least one account from your wallet.")
            }
            setIsConnectingWallet(false)
        } catch (e: any) {
            switch (e.code) {
                case -32002:
                    toast.error("Your wallet is already processing the authentication. Please, check your wallet and try again.")
                    break;
                default:
                    toast.error(e.message)
            }
            setIsConnectingWallet(false)
        }

    }

    return <>
        <div className="container mb-5" style={{position: 'relative'}}>
            <div className="text-center mb-4">
                <h1>Ethereum Coin Flip Game!</h1>
                <h5 style={{color: '#5f6368'}}>
                    {walletAuthContext.currentWallet ?
                        <span>Enter the amount to bet (Credit: {walletAuthContext.currentWallet!.balance} ETH)</span> :
                        "Connect your wallet to start the game"
                    }
                </h5>
            </div>

            <div className="text-center">
                <button className={"btn btn-primary"} onClick={() => handleConnectWallet()} disabled={isConnectingWallet}>
                    {!isConnectingWallet ? <><i className={"fas fa-wallet me-2"}/>Connect wallet</> : <>Connecting wallet <Spinner animation={"border"} size={"sm"}/></>}
                </button>
            </div>
        </div>

        <div className="card">
            <div className="card-body">
                <div className="row">
                    <div className="col-md-4">
                        <h2>The Game</h2>
                        <p>Game is simple, you bet an ether amount and the coin flips, if the coin goes head you'll earn
                            the
                            190% of your bet. If the coin goes tails you'll loose your bet.</p>
                        {/*<p><a className="btn btn-secondary" href="#" role="button">View details &raquo;</a></p> */}
                    </div>
                    <div className="col-md-4">
                        <h2>Requirements</h2>
                        <p>You must install <a href="https://metamask.io/" target="_blank">Metamask</a> in your browser
                            (<a
                                href="https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn"
                                target="_blank">Get Chrome version here!</a>) in order to play the game. Currently we
                            are
                            testing in Goerli ethereum network, so be sure to select it when setup Metamask.</p>
                        {/* <p><a className="btn btn-secondary" href="#" role="button">View details &raquo;</a></p> */}
                    </div>
                    <div className="col-md-4">
                        <h2>No funds?</h2>
                        <p>No problem! We are testing this DApp in the Ethereum Goerli testnet. So you can just create
                            an
                            address in Metamask, go to <a href="https://goerlifaucet.com"
                                                          target="_blank">goerlifaucet.com</a> and follow the
                            instructions
                            to get free ethers from the thin air! ;-)</p>
                        {/* <p><a className="btn btn-secondary" href="#" role="button">View details &raquo;</a></p> */}
                    </div>
                </div>

                <hr/>

                <footer>
                    <p>&copy; {currentDate.getFullYear()} {' '}
                        <a href="https://www.truecoinflip.com" target="_blank">truecoinflip.com</a>
                        {/*{contractBalance && <>
                            Contract Address: <a href={"guerli ethersxan url"} target={"_blank"}>{CONTRACT_ADRESS}</a> /
                            Contract Balance: (balance /  1000000000000000000) ethers /
                            Total Bets:
                        </>}*/}
                    </p>
                </footer>
            </div>
        </div>
    </>
}