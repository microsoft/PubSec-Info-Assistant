// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useEffect, useState } from  "react";
import type { ApplicationTitle } from "../../api"; 
import { getApplicationTitle } from "../../api";

export const Title = () => {
    const [title, setTitle] = useState<ApplicationTitle | null>(null);

    const fetchApplicationTitle = async () =>{
        
        if (process.env.NODE_ENV === 'development') {
            console.log("Fetching Application Title...");
        }

        try {
            const { APPLICATION_TITLE } = await getApplicationTitle();
            if(APPLICATION_TITLE) setTitle({ APPLICATION_TITLE });

        } catch (error) {
            console.error("Error fetching title:", error);
        }
    }

    useEffect(() => {
        fetchApplicationTitle();
    }, []);

    return (<>{title?.APPLICATION_TITLE}</>);
};