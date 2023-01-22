export default function Home(){
    return <>
        <div className="jumbotron">
            <div className="container">

                <p className="text-center" style={{margin: 0}}><i className="cc ETH-alt" title="ETH"
                                                                 style={{fontSize: '6rem'}}></i></p>

                <h1 className="display-3 text-center">Ethereum Coin Flip Game!</h1>
                <p className="text-center">The best ethereum coin flip game of the world</p>

                <div className="row">
                    <div className="col-md-6 offset-md-3">
                        <div className="input-group input-group-lg">
                            <span className="input-group-addon">Amount to Bet:</span>
                            <input type="number" className="form-control" required step=".001" min="0.001" max="1"
                                   value="0.001" id="amount" placeholder="Ethers to bet..."
                                   aria-label="Ethers to bet..." />
                                <span className="input-group-btn">
                                    <button className="btn btn-success" type="button" id="submit">Play!</button>
                                </span>
                        </div>
                    </div>
                </div>

                <p className="text-center">
                    {/*            <img id="loader" src="https://loading.io/spinners/double-ring/lg.double-ring-spinner.gif">*/}
                </p>

                <div id="alert" className="alert alert-dismissible fade show" role="alert">
                    <button type="button" className="close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                    <span id="alertText"><strong>Well done!</strong> You successfully read this important alert message.</span>
                </div>

            </div>
        </div>

        <div className="container">

            <div className="row">
                <div className="col-md-12">

                    <h2 className="text-center">Last 10 Played Games</h2>

                    <p>&nbsp;</p>

                    <div className="table-responsive">
                        <table id="lastPlayedGamesTable" className="table table-striped">
                            <thead>
                            <tr>
                                <th>Address</th>
                                <th>Block Number</th>
                                <th>Block Timestamp</th>
                                <th>Bet</th>
                                <th>Prize</th>
                                <th>Winner</th>
                            </tr>
                            </thead>
                            <tbody>
                            </tbody>
                        </table>
                    </div>

                </div>
            </div>

            <p>&nbsp;</p>

            <div className="row">
                <div className="col-md-4">
                    <h2>The Game</h2>
                    <p>Game is simple, you bet an ether amount and the coin flips, if the coin goes head you'll earn the
                        190% of your bet. If the coin goes tails you'll loose your bet.</p>
                    {/*<p><a class="btn btn-secondary" href="#" role="button">View details &raquo;</a></p> */}
                </div>
                <div className="col-md-4">
                    <h2>Requirements</h2>
                    <p>You must install <a href="https://metamask.io/" target="_blank">Metamask</a> in your browser (<a
                        href="https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn"
                        target="_blank">Get Chrome version here!</a>) in order to play the game. Currently we are
                        testing in Rinkeby ethereum network, so be sure to select it when setup Metamask.</p>
                    {/* <p><a class="btn btn-secondary" href="#" role="button">View details &raquo;</a></p> */}
                </div>
                <div className="col-md-4">
                    <h2>No funds?</h2>
                    <p>No problem! We are testing this DApp in the Ethereum Rinkeby testnet. So you can just create and
                        address in Metamask, go to <a href="https://faucet.rinkeby.io"
                                                      target="_blank">faucet.rinkeby.io</a> and follow the instructions
                        to get free ethers from the thin air! ;-)</p>
                    {/* <p><a class="btn btn-secondary" href="#" role="button">View details &raquo;</a></p> */}
                </div>
            </div>

            <hr />

                <footer>
                    <p>&copy; 2017 <a href="https://www.quequiereshacer.es"
                                      target="_blank">Quequiereshacer.es</a> / <span id="contractInfo"></span></p>
                </footer>
        </div>
        {/* /container */}
    </>
}