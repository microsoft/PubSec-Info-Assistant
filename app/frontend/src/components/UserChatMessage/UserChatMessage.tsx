// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

import styles from "./UserChatMessage.module.css";
import { GlobeSearch20Filled, BuildingMultiple20Filled, Person20Filled, Link16Filled } from "@fluentui/react-icons";
import { Approaches } from "../../api";

interface Props {
    message: string;
    approach: Approaches;
}

export const UserChatMessage = ({ message, approach }: Props) => {
    return (
        <div className={approach == Approaches.GPTDirect ? styles.containerUngrounded : styles.container}>
            <div className={approach == Approaches.ChatWebRetrieveRead ? styles.messageweb : approach == Approaches.ReadRetrieveRead ? styles.messagework : approach == Approaches.GPTDirect ? styles.messageungrounded : styles.messagecompare}>
                {approach == Approaches.ReadRetrieveRead ? 
                    <span style={{ marginRight: '10px' }}><BuildingMultiple20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> : 
                 approach == Approaches.ChatWebRetrieveRead ?   
                    <span style={{ marginRight: '10px' }}><GlobeSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> :
                approach == Approaches.CompareWebWithWork ?
                    <span style={{ marginRight: '10px' }}><GlobeSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/><Link16Filled primaryFill={"rgba(255, 255, 225, 1)"}/><BuildingMultiple20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> :
                approach == Approaches.CompareWorkWithWeb ?
                    <span style={{ marginRight: '10px' }}><BuildingMultiple20Filled primaryFill={"rgba(255, 255, 225, 1)"}/><Link16Filled primaryFill={"rgba(255, 255, 225, 1)"}/><GlobeSearch20Filled primaryFill={"rgba(255, 255, 225, 1)"}/></span> : 
                //else
                    <div className={styles.messageungroundedheader}><div className={styles.messageungroundedicon}><Person20Filled primaryFill={"rgba(0, 0, 0, 0.35)"}/></div><span className={styles.messageungroundedtext}>You</span></div>
                }
                <span className={approach == Approaches.GPTDirect ? styles.userMessageUngrounded : styles.userMessage}>{message}</span>
            </div>
        </div>
    );
};
