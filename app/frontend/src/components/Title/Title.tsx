// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import React, { useEffect, useState } from "react";
import { ApplicationTitle, getApplicationTitle } from "../../api";
import styles from './Title.module.css'
import { Chat48Regular } from "@fluentui/react-icons";

export const Title = () => {
    const [Title, setTitle] = useState<ApplicationTitle | null>(null);

    async function fetchApplicationTitle() {
        console.log("fetch Application Title");
        try {


            const v = await getApplicationTitle();
            if (!v.APPLICATION_TITLE) {
                return null;
            }

            setTitle(v);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchApplicationTitle();
    }, []);

     {/* {Title?.APPLICATION_TITLE || 'HHS Chat GPT'} */}

    return (<div className={styles.titleWithLogoContainer}>
        <Chat48Regular />
        <div className={styles.titleContainer}>           
            <h4 className={styles.titleHero}>HHS</h4>
            <h6 className={styles.titleCaption}>Chat GPT</h6>
        </div>
    </div>);
};