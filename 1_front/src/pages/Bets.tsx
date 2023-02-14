import {useContext, useEffect, useMemo, useState} from "react";
import Web3 from 'web3';
import {toast} from "react-toastify";
import contractABI from '../coinfFlipABI.json'
import {CONTRACT_ADRESS} from "../constants";
import {AbiItem} from "web3-utils";
import {Contract} from "web3-eth-contract";
import {Spinner} from "react-bootstrap";
import {BetModel, BetPlacedEventModel, BetSettledEventModel, WalletModel} from "../models";
import {WalletAuthContext} from "../context/walletAuthContext/WalletAuthContext";
import {Web3Context} from "../context/web3Context/Web3Context";

const currentDate = new Date()

export default function Bets() {
    // const {error, data, isLoading} = useQuery("dogs", () => axios.get<{fileSizeBytes: number, url: string}>("https://random.dog/woof.json"))
    const walletAuthContext = useContext(WalletAuthContext);
    const web3Context = useContext(Web3Context)
    const coinflipContract = new web3Context.instance.eth.Contract(contractABI as AbiItem[], CONTRACT_ADRESS)

    const [amountToBet, setAmountToBet] = useState<string>("0.001");
    const [isBetting, setIsBetting] = useState<boolean>(false)
    const [isLoadingBets, setIsLoadingBets] = useState<boolean>(false)
    const [errorLoadingBets, setErrorLoadingBets] = useState<boolean>(false)
    const [bets, setBets] = useState<BetModel[]>([]);


    useEffect(() => {
        getBets().catch(e => {
            setErrorLoadingBets(true)
            toast.error("Something went wront while fetching bets ...")
            console.error(e)
        })
        listenToBetPlacedEvent()
        listenToBetSettledEvent()
    }, []);


    function listenToBetPlacedEvent() {
        coinflipContract.events.BetPlaced()
            .on('data', async (event: any) => {
                console.log('Bet placed', event)
                const {betId}: BetPlacedEventModel = event.returnValues
                const bet: BetModel = await coinflipContract.methods.bets(betId).call({from: walletAuthContext.currentWallet!.address})
                setBets((prev) => {
                    prev.unshift(bet)
                    return [...prev]
                })
            })
    }

    function listenToBetSettledEvent() {
        coinflipContract.events.BetSettled()
            .on('data', async (event: any) => {
                console.log('Bet settled', event)
                const {betId}: BetSettledEventModel = event.returnValues
                const bet: BetModel = await coinflipContract.methods.bets(betId).call({from: walletAuthContext.currentWallet!.address})
                setBets(prev => {
                    prev[parseInt(betId)] = bet
                    return [...prev]
                })
            })
    }

    async function getBets() {
        setIsLoadingBets(true)
        setBets([])
        setErrorLoadingBets(false)
        let listOfBets: BetModel[] = []
        const betsLength = await coinflipContract.methods.betsLength().call({from: walletAuthContext.currentWallet!.address})

        if (betsLength > 0) {
            Array.from({length: betsLength}, (v, k) => k).map(async index => {
                const bet: BetModel = await coinflipContract.methods.bets(index).call({from: walletAuthContext.currentWallet!.address})
                listOfBets.unshift(bet)
                setBets((prev) => {
                    prev.unshift(bet)
                    return [...prev]
                })
            })
        }
        setIsLoadingBets(false)
        return listOfBets
    }

    // Start betting!
    const handlePlay = async () => {
        setIsBetting(true)
        const amountETH = parseFloat(amountToBet)

        // You cannot bet less than 0.001 ETH
        if (amountETH >= 0.001) {
            const amountWei = amountETH * 1000000000000000000
            // Call Play method from the contract
            coinflipContract.methods.placeBet(amountWei).send({from: walletAuthContext.currentWallet!.address, gas: 3000000})
                .then((r: any) => {
                    const {betId} = r.events.BetPlaced.returnValues
                    coinflipContract.methods.bets(betId).call({from: walletAuthContext.currentWallet!.address})
                        .then((r: BetModel) => {
                            /*  setBets((prev) => {
                                  prev.unshift(r)
                                  return [...prev]
                              })*/
                            toast.info("Your bet has been placed! Wait 1 min for the result.")
                        })

                    /*// @ts-ignore
                    const {winner} = r.events.Status
                    if (winner === true) {
                        toast.success("Congratulations, you won!")
                    } else {
                        toast.error("Sorry, you lost your bet...")
                    }

                    // @ts-ignore
                    // Refresh data of the table of bets
                    hydrateTableOfBets(coinFlipGame.totalGamesPlayed + 1, walletAuthContext.currentWallet!.address)*/
                })
                .catch((e: any) => {
                    toast.error(e)
                })
                .finally(() => setIsBetting(false))
        } else {
            toast.error("You need at least 0.001 ETH to start betting ")
            setIsBetting(false)
        }


    }

    return <>
        <div className="container mb-5" style={{position: 'relative'}}>
            <div className="text-center mb-4">
                <h1>Ethereum Coin Flip Game!</h1>
                <h5 style={{color: '#5f6368'}}>
                    Enter the amount to bet (Credit: {walletAuthContext.currentWallet!.balance} ETH)
                </h5>
            </div>

            <div className={"d-flex justify-content-center"}>
                <div className="input-group my-2 w-50">
                    <input type="number" className="form-control" placeholder="Enter the amount to bet" value={amountToBet} onChange={e => setAmountToBet(e.target.value)}/>
                    <button className="btn btn-success" type="submit" onClick={() => handlePlay()} disabled={isBetting}>
                        {!isBetting ? "Bet !" : <>Betting in progress <Spinner animation={"grow"} size={"sm"}/></>}
                    </button>
                </div>
            </div>
        </div>

        {isLoadingBets ? <div className="card text-center mb-5">
                <h5 className="card-header">
                    Loading Bets <Spinner animation={"grow"} size={"sm"}/>
                </h5>
            </div> :
            <div className="card text-center mb-5">
                <h5 className="card-header">
                    Total bets: {bets.length}
                </h5>
                <div className="card-body">
                    <div className="table-responsive">
                        <table id="lastPlayedGamesTable" className="table table-striped">
                            <thead>
                            <tr>
                                <th>Address</th>
                                <th>Block Number</th>
                                <th>Bet in WEI</th>
                                <th>Result</th>
                            </tr>
                            </thead>
                            <tbody>
                            {bets.map((bet, key) => (
                                <tr key={key}>
                                    <td>{bet.gambler}</td>
                                    <td>{bet.placeBlockNumber}</td>
                                    <td>{bet.amount}</td>
                                    <td>
                                        {bet.outcome === "0" && <span className="badge bg-warning">Ongoing</span>}
                                        {bet.outcome === "1" && <span className="badge bg-success">Won</span>}
                                        {bet.outcome === "2" && <span className="badge bg-danger">Lost</span>}
                                    </td>
                                    {/*<td>{bet.bet}</td>*/}
                                    {/*<td>{bet.prize}</td>*/}
                                    {/*<td>{bet.winner ? <i className={"fas fa-check-circle text-success"}/> : <i className={"fas fa-times-circle text-danger"}/>}</td>*/}
                                </tr>
                            ))}
                            </tbody>
                        </table>
                    </div>
                </div>
                <div className="card-footer text-muted">
                    Last bet 1h ago (non functional)
                </div>
            </div>
        }

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