import {Container, Nav, Navbar} from "react-bootstrap";

export default function Header() {
    return <Navbar collapseOnSelect expand="lg" bg="dark" variant="dark">
        <Container>
            <Navbar.Brand href="#home">True CoinFlip</Navbar.Brand>
            <Navbar.Toggle aria-controls="responsive-navbar-nav"/>
            <Navbar.Collapse id="responsive-navbar-nav">
                <Nav className="me-auto">
                    <Nav.Link href="home">Home</Nav.Link>
                    <Nav.Link href="#">...</Nav.Link>
                </Nav>
                <Nav>
                    <Nav.Link href="#">
                        Connected wallet:
                    </Nav.Link>
                </Nav>
            </Navbar.Collapse>
        </Container>
    </Navbar>
}