// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React from 'react';
import { getStreamlitURI, GetStreamlitURIResponse } from "../../api";
import { useEffect, useState } from "react";
const Tutor = () => {
    const [StreamlitURI, setStreamlitURI] = useState<GetStreamlitURIResponse | null>(null);

    async function fetchStreamlitURI() {
        console.log("Streamlit URI 1");
        try {
            const fetchedStreamlitURI = await getStreamlitURI();
            setStreamlitURI(fetchedStreamlitURI);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchStreamlitURI();
    }, []);
    const StreamlitURIf = StreamlitURI?.STREAMLIT_HOST_URI;
return (
    <div style={{ height: '100vh' }}>
        <iframe src={`http://${StreamlitURIf}:8051`} title="My Streamlit App" style={{ width: '100%', height: '100%' }} />
    </div>

)
};

export default Tutor; // Export the 'Chat' component
