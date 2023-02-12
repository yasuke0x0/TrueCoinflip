import React from 'react';
import './App.css';

import Header from "./pages/Header";
import AppRoutes from "./routes/AppRoutes";

function App() {
    return <>
        {/*Header*/}
        <Header/>

        {/*Body*/}
        <div className={"p-4"}>
            <AppRoutes/>
        </div>

        {/*Footer*/}
    </>
}

export default App;
