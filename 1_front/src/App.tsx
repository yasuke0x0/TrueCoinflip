import React from 'react';
import './App.css';
import Header from "./header/header";

import {createBrowserRouter, RouterProvider} from "react-router-dom";
import Home from "./pages/home/home";

const router = createBrowserRouter([
    {
        path: "/",
        element: <Home />,
    },
]);

function App() {
    return <>
        <Header />
        <div className={"p-4"}>
            <RouterProvider router={router} />
        </div>
    </>
}

export default App;
