// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import { useEffect, useState } from "react";
import { ApplicationTitle, getApplicationTitle, DisclaimerText, getDisclaimerText } from "../../api";
import { PrimaryButton } from "@fluentui/react";
import styles from "./Disclaimer.module.css"
import ReactMarkdown from "react-markdown";
import { CursorClick24Filled } from "@fluentui/react-icons";

export const Disclaimer = ({ onDiclamainerAcceptanceClick }: { onDiclamainerAcceptanceClick: (event: any) => void }) => {
    const [Title, setTitle] = useState<ApplicationTitle | null>(null);
    const [DisclaimerContent, setDisclaimerText] = useState<DisclaimerText | null>(null);

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

    async function fetchDisclaimerText() {
        console.log("fetch Disclaimer Text");
        try {
            const v = await getDisclaimerText();

            if (!v.Content) {
                return null;
            }


            setDisclaimerText(v);
        } catch (error) {
            // Handle the error here
            console.log(error);
        }
    }

    useEffect(() => {
        fetchApplicationTitle();
        fetchDisclaimerText();
    }, []);

    return (<div className={styles.disclaimer}>
        <h3>
            Welcome to  {Title?.APPLICATION_TITLE || 'HHS Chat GPT'}
        </h3>
        <div className={styles.disclaimerTextContainer}>
            <ReactMarkdown>{DisclaimerContent?.Content}</ReactMarkdown>
        </div>
        <div>
            <PrimaryButton className={styles.disclaimerAcceptanceButton} onClick={onDiclamainerAcceptanceClick}>
                <CursorClick24Filled className={styles.clickIcon} />
                Access HHS GPT
            </PrimaryButton>
        </div>
    </div>);
};