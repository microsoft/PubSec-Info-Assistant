// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import styles from "./UserChatMessage.module.css";
import { GlobeSearch20Filled, DocumentSearch20Filled, Sparkle20Filled, Link16Filled } from "@fluentui/react-icons";
import { Approaches } from "../../api";

interface Props {
    message: string;
    approach: Approaches;
}

export const UserChatMessage = ({ message, approach }: Props) => {
    return (
        <div className={styles.container}>
            <div className={approach == Approaches.ChatWebRetrieveRead ? styles.messageweb : approach == Approaches.ReadRetrieveRead ? styles.messagework : styles.messagecompare}>
                {approach == Approaches.ReadRetrieveRead ? 
                    <span style={{ marginRight: '10px' }}><DocumentSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> : 
                 approach == Approaches.ChatWebRetrieveRead ?   
                    <span style={{ marginRight: '10px' }}><GlobeSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> :
                approach == Approaches.CompareWebWithWork ?
                    <span style={{ marginRight: '10px' }}><GlobeSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/><Link16Filled primaryFill={"rgba(255, 255, 225, 1)"}/><DocumentSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> :
                approach == Approaches.CompareWorkWithWeb ?
                    <span style={{ marginRight: '10px' }}><DocumentSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/><Link16Filled primaryFill={"rgba(255, 255, 225, 1)"}/><GlobeSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> : 
                //else
                    <span style={{ marginRight: '10px' }}><Sparkle20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span>
                }
                <span className={styles.userMessage}>{message}</span>
            </div>
        </div>
    );
};
