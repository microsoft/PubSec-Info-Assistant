// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import styles from "./Help.module.css";

const Layout = () => {
    return (
        <div className={styles.padding}>
              <h1 className={styles.chatEmptyStateTitle}>Have a conversation with your private data</h1>
            <span className={styles.chatEmptyObjectives}>
                                The objective of the Information Assistant powered by Azure OpenAI is to leverage a combination of AI components 
                                to enable you to <b>Chat</b> (Have a conversation) with or <b>Ask a question</b> of your own private data. You can use our <b>Upload</b> feature to begin adding your private data now. The Information Assistant attempts to provide responses that are:
                            </span>
                            <ul className={styles.chatEmptyObjectivesList}>
                                <li>Current: Based on the latest “up to date” information in your private data</li>
                                <li>Relevant: Responses should leverage your private data</li>
                                <li>Controlled: You can use the <b>Adjust</b> feature to control the response parameters</li>
                                <li>Referenced: Responses should include specific citations</li>
                                <li>Personalized: Responses should be tailored to your personal settings you <b>Adjust</b> to</li>
                                <li>Explainable: Each response should include details on the <b>Thought Process</b> that was used</li>
                            </ul>
                            <span className={styles.chatEmptyObjectives}>
                                <i>Though the Accelerator is focused on the key areas above, human oversight to confirm accuracy is crucial. 
                                All responses from the system must be verified with the citations provided. 
                                The responses are only as accurate as the data provided.</i>
                            </span>
                          

        </div>
    );
};

export default Layout;
