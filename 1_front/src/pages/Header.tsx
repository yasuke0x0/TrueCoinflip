import {Container, Navbar} from "react-bootstrap";
import {useContext} from "react";
import {WalletAuthContext} from "../context/walletAuthContext/WalletAuthContext";

export default function Header() {
    const walletAuthContext = useContext(WalletAuthContext);

    return <Navbar collapseOnSelect expand="lg" bg="dark" variant="dark">
        <Container>
            <Navbar.Brand href="#home">True CoinFlip</Navbar.Brand>
            {walletAuthContext.currentWallet && (
                <Navbar.Text>
                    <button className={"btn btn-danger"} onClick={() => walletAuthContext.logout()}><i className={"fas fa-power-off "}/> Logout</button>
                </Navbar.Text>
            )}
        </Container>
    </Navbar>
}